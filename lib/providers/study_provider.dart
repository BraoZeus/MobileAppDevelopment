import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_plan_model.dart';
import '../services/database_service.dart';

class StudyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<StudySubject> activeSubjects = [];
  List<StudySubject> historySubjects = [];
  bool isLoadingDB = true;

  StudyProvider() {
    // This is the magic! It listens to the user's login status in real-time.
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in: Fetch their specific data from the cloud
        _initializeDatabase();
      } else {
        // User logged out: Wipe the app's memory instantly
        _clearMemory();
      }
    });
  }

  // Fetch the data from Cloud Firestore
  Future<void> _initializeDatabase() async {
    isLoadingDB = true;
    notifyListeners();

    final allSubjects = await _db.loadAndPurgeData();
    activeSubjects = allSubjects.where((s) => !s.isHistory).toList();
    historySubjects = allSubjects.where((s) => s.isHistory).toList();

    isLoadingDB = false;
    notifyListeners();
  }

  // Centralized save method
  void _saveToCloud() {
    _db.saveAllSubjects([...activeSubjects, ...historySubjects]);
  }

  // Wipes the RAM when a user logs out (No need to touch SharedPreferences anymore!)
  void _clearMemory() {
    activeSubjects = [];
    historySubjects = [];
    isLoadingDB = true;
    notifyListeners();
  }

  // --- DASHBOARD HELPERS ---
  double get overallProgress {
    if (activeSubjects.isEmpty) return 0.0;
    int total = 0;
    int completed = 0;
    for (var subject in activeSubjects) {
      total += subject.topics.length;
      completed += subject.topics.where((t) => t.status == TopicStatus.completed).length;
    }
    return total == 0 ? 0.0 : completed / total;
  }

  StudySubject? get nextUpcomingExam {
    final exams = activeSubjects.where((s) => s.examDate != null).toList();
    if (exams.isEmpty) return null;
    exams.sort((a, b) => a.examDate!.compareTo(b.examDate!));
    return exams.first;
  }

  // --- CRUD OPERATIONS ---
  void addSubject(StudySubject subject) {
    activeSubjects.add(subject);
    _saveToCloud();
    notifyListeners();
  }

  void updateSubjectName(String id, String newName) {
    final index = activeSubjects.indexWhere((s) => s.id == id);
    if (index != -1) {
      activeSubjects[index].name = newName;
      _saveToCloud();
      notifyListeners();
    }
  }

  void deleteSubject(String id) {
    activeSubjects.removeWhere((s) => s.id == id);
    historySubjects.removeWhere((s) => s.id == id);
    _saveToCloud();
    notifyListeners();
  }

  void toggleTopicStatus(StudySubject subject, StudyTopic topic) {
    topic.status = topic.status == TopicStatus.completed ? TopicStatus.pending : TopicStatus.completed;

    if (subject.readiness == 1.0) {
      subject.completedAt = DateTime.now();
      activeSubjects.removeWhere((s) => s.id == subject.id);
      historySubjects.insert(0, subject);
    }

    _saveToCloud();
    notifyListeners();
  }
}