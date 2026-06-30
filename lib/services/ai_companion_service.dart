// lib/services/ai_companion_service.dart
import 'package:firebase_ai/firebase_ai.dart';

class AICompanionService {
  late GenerativeModel _model;
  late ChatSession _chat;

  // Initialize the chat with strict context to save tokens
  void initializeChat({required String subjectName, required String topicName}) {
    // Using gemini-3.1-flash-lite for real-time chat
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      systemInstruction: Content.system(
          'You are an expert AI Study Companion for a university student. '
              'The student is currently studying "$subjectName", specifically focusing on the topic: "$topicName". '
              'Your goal is to answer their questions, quiz them if they ask, and explain concepts simply. '
              'Keep your answers concise, encouraging, and strictly related to the current topic to maximize learning.'
      ),
    );

    // Start a fresh chat session with this specific context
    _chat = _model.startChat();
  }

  // Send a message and get the AI's response
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      return "Connection error: Please check your internet and try again.";
    }
  }
}
