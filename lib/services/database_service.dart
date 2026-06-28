import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Safely gets the current user's specific cloud document
  DocumentReference? get _userDoc {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid);
    }
    return null;
  }


  // Overwrites the cloud document with the latest list of projects
  Future<void> saveAllProjects(List<Project> projects) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    final List<Map<String, dynamic>> encodedData = projects.map((p) => p.toJson()).toList();
    await docRef.set({'projects': encodedData}, SetOptions(merge: true));
  }

  // Pulls project data from the cloud
  Future<List<Project>> loadProjects() async {
    final docRef = _userDoc;
    if (docRef == null) return [];

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists || !(docSnap.data() as Map<String, dynamic>).containsKey('projects')) {
        return [];
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final List<dynamic> rawList = data['projects'] ?? [];

      return rawList.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      print('Firestore Database Error (Projects): $e');
      return [];
    }
  }
}