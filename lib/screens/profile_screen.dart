import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  Future<void> _updateProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
      'studyLevel': _levelController.text,
      'age': int.tryParse(_ageController.text) ?? 20,
    }, SetOptions(merge: true));

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(user?.photoURL ?? 'https://i.pravatar.cc/150')),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? ''),
            const SizedBox(height: 32),
            TextField(controller: _levelController, decoration: const InputDecoration(labelText: 'Study Level (e.g. Undergrad)')),
            TextField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _updateProfile, child: const Text('Save Profile')),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}