// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../models/buddy_level_model.dart';
import '../services/database_service.dart';

class ProfileProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  UserProfile profile = UserProfile();
  bool isLoading = true;

  // Last level-up result — cleared after being consumed by the UI
  BuddyLevel? _pendingLevelUp;
  BuddyLevel? get pendingLevelUp => _pendingLevelUp;
  void consumeLevelUp() {
    _pendingLevelUp = null;
    notifyListeners();
  }

  bool get isOnboardingComplete => profile.isOnboardingComplete;

  ProfileProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadProfile();
      } else {
        profile = UserProfile();
        isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    isLoading = true;
    notifyListeners();

    final loadedProfile = await _db.loadUserSettings();
    profile = loadedProfile ?? UserProfile();

    isLoading = false;
    notifyListeners();
  }

  /// Awards XP for completing a topic (+15 XP per topic).
  /// Detects level-up and exposes it via [pendingLevelUp].
  Future<void> addXp(int amount) async {
    final levelBefore = profile.buddyLevel.level;
    profile.xp += amount;
    profile.totalTopicsCompleted += 1;
    final levelAfter = profile.buddyLevel.level;

    if (levelAfter > levelBefore) {
      _pendingLevelUp = profile.buddyLevel;
    }

    await _db.saveUserSettings(profile);
    notifyListeners();
  }

  /// Updates one or more profile fields and persists to Firestore.
  Future<void> updateProfile({
    String? displayName,
    int? age,
    String? avatar,
    String? level,
    String? university,
    String? major,
    String? yearOfStudy,
    String? goals,
  }) async {
    if (displayName != null) profile.displayName = displayName;
    if (age != null) profile.age = age;
    if (avatar != null) profile.avatarEmoji = avatar;
    if (level != null) profile.studyLevel = level;
    if (university != null) profile.university = university;
    if (major != null) profile.major = major;
    if (yearOfStudy != null) profile.yearOfStudy = yearOfStudy;
    if (goals != null) profile.goals = goals;

    await _db.saveUserSettings(profile);
    notifyListeners();
  }

  /// Called at the end of onboarding to mark setup as complete.
  Future<void> completeOnboarding({
    required String displayName,
    required int age,
    required String studyLevel,
    required String yearOfStudy,
    String university = '',
    String major = '',
    String goals = '',
    String avatarEmoji = '🎓',
  }) async {
    profile
      ..displayName = displayName
      ..age = age
      ..studyLevel = studyLevel
      ..yearOfStudy = yearOfStudy
      ..university = university
      ..major = major
      ..goals = goals
      ..avatarEmoji = avatarEmoji
      ..isOnboardingComplete = true;

    await _db.saveUserSettings(profile);
    notifyListeners();
  }
}
