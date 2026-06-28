import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Project> projects = [];
  bool isLoadingDB = true;

  ProjectProvider() {
    // Same auth listener pattern as StudyProvider.
    // Loads data on login, clears it on logout automatically.
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadFromCloud();
      } else {
        _clearMemory();
      }
    });
  }

  Future<void> _loadFromCloud() async {
    isLoadingDB = true;
    notifyListeners();
    projects = await _db.loadProjects();
    isLoadingDB = false;
    notifyListeners();
  }

  void _saveToCloud() {
    _db.saveAllProjects(projects);
  }

  void _clearMemory() {
    projects = [];
    isLoadingDB = true;
    notifyListeners();
  }

  // --- CRUD ---

  void addProject(Project project) {
    projects.add(project);
    _saveToCloud();
    NotificationService.scheduleForProject(project);
    notifyListeners();
  }

  void updateProject(Project updated) {
    final index = projects.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    projects[index] = updated;
    _saveToCloud();
    NotificationService.scheduleForProject(updated);
    notifyListeners();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    _saveToCloud();
    NotificationService.cancelForProject(id);
    notifyListeners();
  }

  // Flips a subtask's completion state and recalculates progress automatically
  // (progress is a getter so it updates on its own — no manual recalc needed)
  void toggleSubtask(Project project, Subtask subtask) {
    subtask.isCompleted = !subtask.isCompleted;
    if (subtask.isCompleted) {
      NotificationService.showMilestone(project, subtask.title);
    }
    _saveToCloud();
    notifyListeners();
  }

  // Named params match the exact calls in projects_screen.dart
  void updateProjectAlerts(Project project, {bool? oneDay, bool? morning, bool? milestone}) {
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index == -1) return;
    if (oneDay != null) projects[index].alert1Day = oneDay;
    if (morning != null) projects[index].alertMorning = morning;
    if (milestone != null) projects[index].alertMilestone = milestone;
    _saveToCloud();
    NotificationService.scheduleForProject(projects[index]);
    notifyListeners();
  }
}