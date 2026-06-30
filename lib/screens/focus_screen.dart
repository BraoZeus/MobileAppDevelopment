import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../models/study_plan_model.dart';
import '../services/ai_companion_service.dart';
import '../widgets/wellness_overlays.dart';

class FocusScreen extends StatefulWidget {
  final StudySubject subject;
  final StudyTopic topic;

  const FocusScreen({super.key, required this.subject, required this.topic});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with SingleTickerProviderStateMixin {

// STATE VARIABLES & INITIALIZATION
// Holds timer data, AI chat controllers, and health tips for the exit prompt.
late int _remainingSeconds;
Timer? _timer;
bool _isRunning = false;
int _elapsedSeconds = 0;

final AICompanionService _aiService = AICompanionService();
final TextEditingController _chatController = TextEditingController();
final List<Map<String, String>> _messages = [];
bool _isTyping = false;
final ScrollController _scrollController = ScrollController();

final List<String> _healthTips = [
"Tip: Feeling stuck? A quick 5-minute stretch improves retention by 20%!",
"Tip: Hydration boosts brain function. Go drink a glass of water!",
"Tip: Deep breathing lowers stress and increases focus. Try it out!",
"Tip: Rest is productive. Taking breaks actually prevents burnout."
];

@override
void initState() {
super.initState();
_remainingSeconds = widget.topic.durationMinutes * 60;
_aiService.initializeChat(subjectName: widget.subject.name, topicName: widget.topic.title);
_messages.add({'role': 'ai', 'text': 'Ready to focus on "${widget.topic.title}"! Remember to take a mindful break if you feel overwhelmed.'});
}

@override
void dispose() {
_timer?.cancel();
_chatController.dispose();
_scrollController.dispose();
super.dispose();
}

// TIMER LOGIC
// Handles play/pause, time formatting, session completion, and auto-prompts.
void _toggleTimer() {
if (_isRunning) {
_timer?.cancel();
} else {
  if (_elapsedSeconds == 0) {
    context.read<StudyProvider>().startTopicTimer(widget.subject, widget.topic);
  }
_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
if (_remainingSeconds > 0) {
setState(() {
_remainingSeconds--;
_elapsedSeconds++;
});
if (_elapsedSeconds > 0 && _elapsedSeconds % (25 * 60) == 0) {
_showAutoBreakPrompt();
}
} else {
_timer?.cancel();
_completeSession();
}
});
}
setState(() => _isRunning = !_isRunning);
}

String get _formattedTime {
int minutes = _remainingSeconds ~/ 60;
int seconds = _remainingSeconds % 60;
return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

void _completeSession() {
_timer?.cancel();
context.read<StudyProvider>().toggleTopicStatus(widget.subject, widget.topic);
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session Completed! Awesome work!'), backgroundColor: Colors.green));
Navigator.pop(context);
}

// WELLNESS NAVIGATION
// Triggers the 25-minute Pomodoro popup and handles the sliding bottom menu.
void _showAutoBreakPrompt() {
if (_isRunning) _toggleTimer();
showDialog(
context: context,
barrierDismissible: false,
builder: (context) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('Pomodoro Reached!'),
content: const Text('25 minutes focused. Take a 5-minute break to maintain performance.'),
actions: [
TextButton(onPressed: () { Navigator.pop(context); _toggleTimer(); }, child: const Text('Skip')),
ElevatedButton(onPressed: () { Navigator.pop(context); _openWellnessMenu(); }, child: const Text('Take Break')),
]
),
);
}

void _openWellnessMenu() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (context) => Container(
padding: const EdgeInsets.all(24),
decoration: const BoxDecoration(color: Color(0xFFF8F9FA), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
const SizedBox(height: 24),
_buildWellnessOption(icon: Icons.air, title: '4-7-8 Breathing', subtitle: 'Reduce stress (1.5 mins)', color: Colors.teal, onTap: () { Navigator.pop(context); _startWellness(const MindfulBreathingOverlay()); }),
const SizedBox(height: 12),
_buildWellnessOption(icon: Icons.water_drop, title: 'Hydration Break', subtitle: 'Drink a glass of water', color: Colors.blue, onTap: () { Navigator.pop(context); _startWellness(const HydrationOverlay()); }),
const SizedBox(height: 12),
_buildWellnessOption(icon: Icons.directions_walk, title: 'Guided Stretch', subtitle: '60-second routine', color: Colors.orange, onTap: () { Navigator.pop(context); _startWellness(const StretchOverlay()); }),
],
),
),
);
}

void _startWellness(Widget overlay) {
if (_isRunning) _toggleTimer();
showGeneralDialog(context: context, barrierDismissible: false, pageBuilder: (context, anim, secAnim) => overlay);
}

Widget _buildWellnessOption({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.grey))]))])));
}

// AI CHAT LOGIC
// Processes user messages and automatically scrolls to the newest response.
Future<void> _sendMessage() async {
final text = _chatController.text.trim();
if (text.isEmpty) return;
setState(() { _messages.add({'role': 'user', 'text': text}); _isTyping = true; });
_chatController.clear();
_scrollToBottom();
final response = await _aiService.sendMessage(text);
setState(() { _messages.add({'role': 'ai', 'text': response}); _isTyping = false; });
_scrollToBottom();
}

void _scrollToBottom() {
Future.delayed(const Duration(milliseconds: 100), () {
if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
});
}
// MAIN UI BUILDER
  // Constructs the layout including the Smart Exit PopScope and main Scaffold.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final randomTip = _healthTips[Random().nextInt(_healthTips.length)];
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Focus Mode?'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Your timer will reset.'), const SizedBox(height: 16), Text(randomTip, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue))]),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit', style: TextStyle(color: Colors.red)))],
          ),
        );
        if (shouldExit == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF2D3142)), onPressed: () => Navigator.maybePop(context)), title: Text(widget.subject.name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 16)), actions: [IconButton(icon: Icon(Icons.self_improvement_rounded, color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195)), onPressed: _openWellnessMenu)]),
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? const [Color(0xFF111318), Color(0xFF1A1D2E), Color(0xFF111827)] : const [Color(0xFFE8F0FA), Color(0xFFF3E8FA), Color(0xFFE0F7FA)])),
          child: SafeArea(
            child: Column(
              children: [
                _buildTimerSection(screenWidth, isDark),
                Expanded(child: _buildChatSection(screenWidth, isDark)),
                _buildChatInput(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

// UI SUB-COMPONENTS
  // Timer Display, Chat List View, and Input TextField layout structures.
  Widget _buildTimerSection(double screenWidth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8), width: 1.5)),
            child: Column(
              children: [
                Text(widget.topic.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 8),
                Text(_formattedTime, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: _isRunning ? Colors.orange.shade400 : const Color(0xFF334195), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: _toggleTimer, icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow), label: Text(_isRunning ? 'Pause' : 'Start'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: _completeSession, icon: const Icon(Icons.check_circle_outline), label: const Text('Finish')))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(double screenWidth, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))));
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: isUser ? (isDark ? const Color(0xFF4A5FC1) : const Color(0xFF334195)) : (isDark ? const Color(0xFF252840) : Colors.white.withValues(alpha: 0.8)), borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16))),
            child: Text(msg['text']!, style: TextStyle(color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF2D3142)))),
          ),
        );
      },
    );
  }

  Widget _buildChatInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1F2A) : Colors.white),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142)),
                decoration: InputDecoration(
                  hintText: 'Ask the AI...', 
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  filled: true, 
                  fillColor: isDark ? const Color(0xFF252840) : Colors.grey.shade100, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: Icon(Icons.send_rounded, color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195)), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
