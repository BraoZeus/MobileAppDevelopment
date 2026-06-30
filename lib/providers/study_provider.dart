import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_plan_model.dart';
import '../services/database_service.dart';
import 'profile_provider.dart';

class StudyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<StudySubject> _subjects = [];
  bool isLoading = true;

  // Injected so we can award XP when topics are completed
  ProfileProvider? _profileProvider;
  void setProfileProvider(ProfileProvider pp) => _profileProvider = pp;

  StudyProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadData();
      } else {
        clearAllData();
      }
    });
  }

  Future<void> _loadData() async {
    isLoading = true;
    notifyListeners();
    _subjects = await _db.loadAndPurgeData();
    isLoading = false;
    notifyListeners();
  }

  List<StudySubject> get activeSubjects =>
      _subjects.where((s) => !s.isHistory).toList();
  List<StudySubject> get historySubjects =>
      _subjects.where((s) => s.isHistory).toList();

  double get overallProgress {
    if (activeSubjects.isEmpty) return 0.0;
    double total = 0;
    for (var s in activeSubjects) {
      total += s.readiness;
    }
    return total / activeSubjects.length;
  }

  StudySubject? get nextUpcomingExam {
    final exams = activeSubjects.where((s) => s.examDate != null).toList();
    if (exams.isEmpty) return null;
    exams.sort((a, b) => a.examDate!.compareTo(b.examDate!));
    return exams.first;
  }

  void addSubject(StudySubject subject) {
    _subjects.add(subject);
    _db.saveSubject(subject);
    notifyListeners();
  }

  void updateSubjectName(String id, String newName) {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subjects[index].name = newName;
      _db.saveSubject(_subjects[index]);
      notifyListeners();
    }
  }

  void updateExamName(String id, String newName) {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subjects[index].examName = newName;
      _db.saveSubject(_subjects[index]);
      notifyListeners();
    }
  }

  /// Updates (or clears) the exam date for a subject.
  void updateExamDate(String id, DateTime? newDate) {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subjects[index].examDate = newDate;
      _db.saveSubject(_subjects[index]);
      notifyListeners();
    }
  }

  /// Sets the started date when a topic's timer starts for the first time.
  void startTopicTimer(StudySubject subject, StudyTopic topic) {
    final sIndex = _subjects.indexWhere((s) => s.id == subject.id);
    if (sIndex == -1) return;

    final tIndex = _subjects[sIndex].topics.indexWhere((t) => t.id == topic.id);
    if (tIndex == -1) return;

    bool needsSave = false;

    if (_subjects[sIndex].topics[tIndex].startedAt == null) {
      _subjects[sIndex].topics[tIndex].startedAt = DateTime.now();
      needsSave = true;
    }

    if (_subjects[sIndex].startDate == null) {
      _subjects[sIndex].startDate = DateTime.now();
      needsSave = true;
    }

    if (needsSave) {
      _db.saveSubject(_subjects[sIndex]);
      notifyListeners();
    }
  }

  /// Toggles a topic's completion status.
  /// Awards +15 XP to the user if the topic is being marked complete for the first time.
  void toggleTopicStatus(StudySubject subject, StudyTopic topic) {
    final sIndex = _subjects.indexWhere((s) => s.id == subject.id);
    if (sIndex == -1) return;

    final tIndex =
        _subjects[sIndex].topics.indexWhere((t) => t.id == topic.id);
    if (tIndex == -1) return;

    final wasCompleted =
        _subjects[sIndex].topics[tIndex].status == TopicStatus.completed;

    _subjects[sIndex].topics[tIndex].status =
        wasCompleted ? TopicStatus.pending : TopicStatus.completed;

    // Award XP only when marking as complete AND topic hasn't already given XP
    if (!wasCompleted && !_subjects[sIndex].xpAwardedTopicIds.contains(topic.id)) {
      _subjects[sIndex].xpAwardedTopicIds.add(topic.id);
      _profileProvider?.addXp(15);
    }

    if (!wasCompleted) {
      _subjects[sIndex].topics[tIndex].completedAt = DateTime.now();
      _subjects[sIndex].topics[tIndex].startedAt ??= _subjects[sIndex].topics[tIndex].createdAt;
    } else {
      _subjects[sIndex].topics[tIndex].completedAt = null;
    }

    final allDone = _subjects[sIndex].topics
        .every((t) => t.status == TopicStatus.completed);
    _subjects[sIndex].isHistory = allDone;
    if (allDone) {
      _subjects[sIndex].completedAt = DateTime.now();
    } else {
      _subjects[sIndex].completedAt = null;
    }

    _db.saveSubject(_subjects[sIndex]);
    notifyListeners();
  }

  void editTopic(StudySubject subject, StudyTopic topic, String newTitle, String? newDescription, int newDuration) {
    final sIndex = _subjects.indexWhere((s) => s.id == subject.id);
    if (sIndex == -1) return;

    final tIndex = _subjects[sIndex].topics.indexWhere((t) => t.id == topic.id);
    if (tIndex == -1) return;

    _subjects[sIndex].topics[tIndex].title = newTitle;
    _subjects[sIndex].topics[tIndex].description = newDescription;
    _subjects[sIndex].topics[tIndex].durationMinutes = newDuration;

    _db.saveSubject(_subjects[sIndex]);
    notifyListeners();
  }

  void deleteTopic(StudySubject subject, StudyTopic topic) {
    final sIndex = _subjects.indexWhere((s) => s.id == subject.id);
    if (sIndex == -1) return;

    _subjects[sIndex].topics.removeWhere((t) => t.id == topic.id);

    // Re-evaluate history status if we deleted the last pending topic
    final allDone = _subjects[sIndex].topics.isNotEmpty && 
        _subjects[sIndex].topics.every((t) => t.status == TopicStatus.completed);
    
    _subjects[sIndex].isHistory = allDone;
    if (allDone) {
      _subjects[sIndex].completedAt = DateTime.now();
    } else {
      _subjects[sIndex].completedAt = null;
    }

    _db.saveSubject(_subjects[sIndex]);
    notifyListeners();
  }

  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
    _db.deleteSubject(id);
    notifyListeners();
  }

  void clearAllData() {
    _subjects.clear();
    notifyListeners();
  }
}
