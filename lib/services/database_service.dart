import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_plan_model.dart';
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

  // Overwrites the cloud document with the latest list of subjects
  Future<void> saveAllSubjects(List<StudySubject> subjects) async {
    final docRef = _userDoc;
    if (docRef == null) return; // Failsafe: Do nothing if no user is logged in

    // Convert Dart objects into JSON maps for Firestore
    final List<Map<String, dynamic>> encodedData = subjects.map((s) => s.toJson()).toList();

    // SetOptions(merge: true) ensures we don't accidentally delete other user settings later
    await docRef.set({'study_plans': encodedData}, SetOptions(merge: true));
  }

  // Pulls data from the cloud and cleans up old history
  Future<List<StudySubject>> loadAndPurgeData() async {
    final docRef = _userDoc;
    if (docRef == null) return [];

    try {
      final docSnap = await docRef.get();

      // If the user is brand new or has no plans yet
      if (!docSnap.exists || !(docSnap.data() as Map<String, dynamic>).containsKey('study_plans')) {
        return [];
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final List<dynamic> rawList = data['study_plans'] ?? [];

      List<StudySubject> allSubjects = rawList.map((json) => StudySubject.fromJson(json)).toList();

      final now = DateTime.now();
      final List<StudySubject> validSubjects = [];
      bool requiresResave = false;

      // --- 30-DAY CLOUD PURGE LOGIC ---
      for (var subject in allSubjects) {
        final daysOld = now.difference(subject.createdAt).inDays;

        if (daysOld >= 30 && subject.isHistory) {
          requiresResave = true;
        } else {
          validSubjects.add(subject);
        }
      }

      // Automatically sync the cleaned-up list back to the cloud
      if (requiresResave) {
        await saveAllSubjects(validSubjects);
      }

      return validSubjects;
    } catch (e) {
      print('Firestore Database Error: $e');
      return [];
    }
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