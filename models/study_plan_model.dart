import 'package:uuid/uuid.dart';

enum TopicStatus { pending, inProgress, completed }

// UI STATE MODELS
class StudyTopic {
  final String id;
  String title;
  String? description; // <-- NEW: Separates long text from the clean title
  int durationMinutes;
  int timeSpentMinutes;
  TopicStatus status;

  StudyTopic({
    String? id,
    required this.title,
    this.description, // <-- NEW
    required this.durationMinutes,
    this.timeSpentMinutes = 0,
    this.status = TopicStatus.pending,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description, // <-- NEW
    'durationMinutes': durationMinutes,
    'timeSpentMinutes': timeSpentMinutes,
    'status': status.index,
  };

  factory StudyTopic.fromJson(Map<String, dynamic> json) => StudyTopic(
    id: json['id'],
    title: json['title'],
    description: json['description'], // <-- NEW
    durationMinutes: json['durationMinutes'],
    timeSpentMinutes: json['timeSpentMinutes'] ?? 0,
    status: TopicStatus.values[json['status'] ?? 0],
  );
}

class StudySubject {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime startDate; // <-- NEW: For precise scheduling
  DateTime? completedAt;
  DateTime? examDate;
  List<StudyTopic> topics;
  bool isExpanded;
  bool isHistory; // <-- FIXED: Now saves to Firestore properly
  Set<String> xpAwardedTopicIds; // Tracks topics that already contributed XP

  StudySubject({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? startDate,
    this.completedAt,
    this.examDate,
    required this.topics,
    this.isExpanded = false,
    this.isHistory = false,
    Set<String>? xpAwardedTopicIds,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        startDate = startDate ?? DateTime.now(),
        xpAwardedTopicIds = xpAwardedTopicIds ?? {};

  double get readiness {
    if (topics.isEmpty) return 0.0;
    int completed = topics.where((t) => t.status == TopicStatus.completed).length;
    return completed / topics.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate.toIso8601String(), // Saves to DB
    'completedAt': completedAt?.toIso8601String(),
    'examDate': examDate?.toIso8601String(),
    'topics': topics.map((t) => t.toJson()).toList(),
    'isExpanded': isExpanded,
    'isHistory': isHistory,
    'xpAwardedTopicIds': xpAwardedTopicIds.toList(),
  };

  factory StudySubject.fromJson(Map<String, dynamic> json) => StudySubject(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    examDate: json['examDate'] != null ? DateTime.parse(json['examDate']) : null,
    topics: (json['topics'] as List).map((t) => StudyTopic.fromJson(t)).toList(),
    isExpanded: json['isExpanded'] ?? false,
    isHistory: json['isHistory'] ?? false,
    xpAwardedTopicIds: json['xpAwardedTopicIds'] != null
        ? Set<String>.from(json['xpAwardedTopicIds'] as List)
        : {},
  );
}

// AI JSON PARSING MODELS
class StudyTask {
  final String taskName;
  final int durationMinutes;
  final String description;
  bool isCompleted;

  StudyTask({
    required this.taskName,
    required this.durationMinutes,
    required this.description,
    this.isCompleted = false,
  });

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      taskName: json['taskName'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 30,
      description: json['description'] ?? '',
      isCompleted: false,
    );
  }
}

class GeneratedStudyPlan {
  final String topic;
  final String overallStrategy;
  final List<StudyTask> tasks;
  final DateTime? examDate;

  GeneratedStudyPlan({
    required this.topic,
    required this.overallStrategy,
    required this.tasks,
    this.examDate,
  });

  factory GeneratedStudyPlan.fromJson(Map<String, dynamic> json, {DateTime? examDate}) {
    var list = json['tasks'] as List? ?? [];
    List<StudyTask> taskList = list.map((i) => StudyTask.fromJson(i)).toList();

    return GeneratedStudyPlan(
      topic: json['topic'] ?? '',
      overallStrategy: json['overallStrategy'] ?? '',
      tasks: taskList,
      examDate: examDate,
    );
  }
}
