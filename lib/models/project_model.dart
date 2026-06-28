import 'package:uuid/uuid.dart';

class Subtask {
  final String id;
  String title;
  bool isCompleted;

  Subtask({
    String? id,
    required this.title,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  // Convert to Firebase JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  // Convert from Firebase JSON
  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'] ?? false,
  );
}

class Project {
  final String id;
  final String title;
  final String tag;
  final String tagColorHex;
  final DateTime dueDate;
  List<Subtask> subtasks;
  bool alert1Day;
  bool alertMorning;
  bool alertMilestone;

  Project({
    String? id,
    required this.title,
    required this.tag,
    required this.tagColorHex,
    required this.dueDate,
    required this.subtasks,
    this.alert1Day = false,
    this.alertMorning = false,
    this.alertMilestone = false,
  }) : id = id ?? const Uuid().v4();

  // Dynamically calculate progress based on subtasks
  double get progress {
    if (subtasks.isEmpty) return 0.0;
    int completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  // Convert to Firebase JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'tag': tag,
    'tagColorHex': tagColorHex,
    'dueDate': dueDate.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'alert1Day': alert1Day,
    'alertMorning': alertMorning,
    'alertMilestone': alertMilestone,
  };

  // Convert from Firebase JSON
  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    title: json['title'] ?? '',
    tag: json['tag'] ?? '',
    tagColorHex: json['tagColorHex'] ?? '#334195',
    dueDate: DateTime.parse(json['dueDate']),
    subtasks: (json['subtasks'] as List? ?? [])
        .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
        .toList(),
    alert1Day: json['alert1Day'] ?? false,
    alertMorning: json['alertMorning'] ?? false,
    alertMilestone: json['alertMilestone'] ?? false,
  );
}