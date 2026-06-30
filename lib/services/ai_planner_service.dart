import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/study_plan_model.dart';

class AIPlannerService {
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite',
  );

  // 1. The original method: User provides specific topics
  Future<GeneratedStudyPlan> generateTargetedPlan({
    required String subject,
    required List<String> userTopics,
    DateTime? examDate,
  }) async {
    try {
      int availableDays = examDate != null ? examDate.difference(DateTime.now()).inDays : 14;
      if (availableDays <= 0) availableDays = 1;

      String urgencyContext = examDate != null
          ? "CRITICAL: The exam is in exactly $availableDays days. The time allocated MUST fit within this window."
          : "The user is studying at a normal pace.";

      String topicsList = userTopics.join(', ');

      final prompt = '''
      You are an expert academic coordinator. The student is studying "$subject".
      They must cover these specific subtopics: $topicsList.
      
      $urgencyContext
      
      Create a structured plan breaking down those exact subtopics into actionable study sessions.
      CRITICAL: Each task MUST have a realistic duration between 30 and 120 minutes, representing a single focused study session, regardless of the time until the exam. Do not assign huge continuous hours.

      You MUST respond ONLY with a raw JSON object matching this schema exactly. No markdown.
      {
        "topic": "$subject",
        "overallStrategy": "Brief strategy tailored to the timeframe.",
        "tasks": [
          {
            "taskName": "Subtopic title",
            "durationMinutes": 45,
            "description": "Specific focus for this session"
          }
        ]
      }
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text, examDate);
    } catch (e) {
      throw Exception('Failed to generate targeted plan: $e');
    }
  }

  // 2. THE NEW METHOD: Auto-generates a syllabus from scratch
  Future<GeneratedStudyPlan> generateAutoSyllabus({
    required String subject,
    DateTime? examDate,
  }) async {
    try {
      int availableDays = examDate != null ? examDate.difference(DateTime.now()).inDays : 14;
      if (availableDays <= 0) availableDays = 1;

      final prompt = '''
      You are an expert curriculum designer. The student needs to study "$subject" but does not know where to start.
      They have $availableDays days to master this.
      
      Generate a standard, highly effective chronological syllabus containing 5 to 7 core subtopics to master "$subject".
      Order them logically from foundational concepts to advanced application.
      CRITICAL: Each task MUST have a realistic duration between 30 and 120 minutes, representing a single focused study session. Do not assign huge continuous hours.

      You MUST respond ONLY with a raw JSON object matching this schema exactly. No markdown.
      {
        "topic": "$subject",
        "overallStrategy": "A 1-sentence strategy on how to tackle this subject from scratch.",
        "tasks": [
          {
            "taskName": "Foundational Concept 1",
            "durationMinutes": 60,
            "description": "What to learn first"
          }
        ]
      }
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text, examDate);
    } catch (e) {
      throw Exception('Failed to auto-generate syllabus: $e');
    }
  }

  // Helper method to keep code clean and dry
  GeneratedStudyPlan _parseJsonResponse(String? responseText, DateTime? examDate) {
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Received an empty response from the AI.');
    }
    String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
    final Map<String, dynamic> parsedJson = jsonDecode(cleanJson);
    return GeneratedStudyPlan.fromJson(parsedJson, examDate: examDate);
  }
}
