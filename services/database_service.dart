import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_plan_model.dart';
import '../models/user_profile_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

// 1. CORE STUDY PLANS (SUBCOLLECTION)
  CollectionReference? get _studyPlansCollection {
    final user = _auth.currentUser;
    return user != null
        ? _firestore.collection('users').doc(user.uid).collection('study_plans')
        : null;
  }

  Future<void> saveSubject(StudySubject subject) async {
    final collection = _studyPlansCollection;
    if (collection != null) {
      await collection.doc(subject.id).set(subject.toJson(), SetOptions(merge: true));
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    final collection = _studyPlansCollection;
    if (collection != null) {
      await collection.doc(subjectId).delete();
    }
  }

  Future<List<StudySubject>> loadAndPurgeData() async {
    final collection = _studyPlansCollection;
    if (collection == null) return [];

    try {
      final querySnapshot = await collection.get();
      if (querySnapshot.docs.isEmpty) return [];

      final now = DateTime.now();
      final List<StudySubject> validSubjects = [];
      final batch = _firestore.batch();
      bool requiresPurge = false;

      for (var doc in querySnapshot.docs) {
        final subject = StudySubject.fromJson(doc.data() as Map<String, dynamic>);
        final daysOld = now.difference(subject.createdAt).inDays;

        if (daysOld >= 30 && subject.isHistory) {
          batch.delete(doc.reference);
          requiresPurge = true;
        } else {
          validSubjects.add(subject);
        }
      }

      if (requiresPurge) {
        await batch.commit();
        debugPrint('Purged old study plans from subcollection.');
      }

      return validSubjects;
    } catch (e) {
      debugPrint('Firestore Subcollection Error: $e');
      return [];
    }
  }

// 2. USER SETTINGS & PERSONA DATA
  DocumentReference? get _settingsDoc {
    final user = _auth.currentUser;
    return user != null ? _firestore.collection('user_settings').doc(user.uid) : null;
  }

  Future<void> saveUserSettings(UserProfile profile) async {
    final docRef = _settingsDoc;
    if (docRef != null) {
      await docRef.set(profile.toJson(), SetOptions(merge: true));
    }
  }

  Future<UserProfile?> loadUserSettings() async {
    final docRef = _settingsDoc;
    if (docRef == null) return null;

    try {
      final docSnap = await docRef.get();
      if (docSnap.exists && docSnap.data() != null) {
        return UserProfile.fromJson(docSnap.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Settings DB Error: $e');
    }
    return UserProfile();
  }
}
