// lib/models/user_profile_model.dart
import 'buddy_level_model.dart';

class UserProfile {
  String displayName;
  int age;
  String avatarEmoji;
  String studyLevel;    // e.g., "Undergraduate", "Postgraduate"
  String university;    // optional
  String major;         // optional
  String yearOfStudy;   // e.g., "Year 1", "Year 2", etc.
  String goals;         // optional motivational goals
  bool isOnboardingComplete;
  int xp;               // cumulative experience points
  int totalTopicsCompleted; // for stats

  UserProfile({
    this.displayName = '',
    this.age = 18,
    this.avatarEmoji = '🎓',
    this.studyLevel = 'Undergraduate',
    this.university = '',
    this.major = '',
    this.yearOfStudy = 'Year 1',
    this.goals = '',
    this.isOnboardingComplete = false,
    this.xp = 0,
    this.totalTopicsCompleted = 0,
  });

  /// Current buddy level derived from XP
  BuddyLevel get buddyLevel => buddyLevelFromXp(xp);

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'age': age,
    'avatarEmoji': avatarEmoji,
    'studyLevel': studyLevel,
    'university': university,
    'major': major,
    'yearOfStudy': yearOfStudy,
    'goals': goals,
    'isOnboardingComplete': isOnboardingComplete,
    'xp': xp,
    'totalTopicsCompleted': totalTopicsCompleted,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] ?? '',
    age: json['age'] ?? 18,
    avatarEmoji: json['avatarEmoji'] ?? '🎓',
    studyLevel: json['studyLevel'] ?? 'Undergraduate',
    university: json['university'] ?? '',
    major: json['major'] ?? '',
    yearOfStudy: json['yearOfStudy'] ?? 'Year 1',
    goals: json['goals'] ?? '',
    isOnboardingComplete: json['isOnboardingComplete'] ?? false,
    xp: json['xp'] ?? 0,
    totalTopicsCompleted: json['totalTopicsCompleted'] ?? 0,
  );
}
