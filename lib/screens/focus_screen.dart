import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../models/study_plan_model.dart';
import '../services/ai_companion_service.dart';

class FocusScreen extends StatefulWidget {
  final StudySubject subject;
  final StudyTopic topic;

  const FocusScreen({super.key, required this.subject, required this.topic});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  final AICompanionService _aiService = AICompanionService();
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.topic.durationMinutes * 60;

    _aiService.initializeChat(
        subjectName: widget.subject.name,
        topicName: widget.topic.title
    );

    _messages.add({
      'role': 'ai',
      'text': 'Hi! We are focusing on "${widget.topic.title}" today. Let me know if you need explanations, a quick quiz, or help breaking down a concept!',
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session Completed!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });

    _chatController.clear();
    _scrollToBottom();

    final response = await _aiService.sendMessage(text);
    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- RESPONSIVE LAYOUT CALCULATION ---
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Focus Mode?'),
            content: const Text('Your timer will reset if you leave.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142)),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Focus Mode', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F0FA), Color(0xFFF3E8FA), Color(0xFFE0F7FA)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTimerSection(screenWidth),
                const Divider(height: 1, color: Colors.black12),
                Expanded(child: _buildChatSection(screenWidth)),
                _buildChatInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: screenWidth * 0.9, // DYNAMIC WIDTH
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            ),
            child: Column(
              children: [
                Text(widget.topic.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 16),
                Text(_formattedTime, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFF334195), letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'play_pause',
                      backgroundColor: _isRunning ? Colors.orange.shade400 : const Color(0xFF334195),
                      elevation: 0,
                      onPressed: _toggleTimer,
                      child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _completeSession,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finish'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(double screenWidth) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: screenWidth * 0.75), // DYNAMIC CONSTRAINTS
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF334195) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Text(msg['text']!, style: TextStyle(color: isUser ? Colors.white : const Color(0xFF2D3142))),
          ),
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Ask the AI...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF334195)), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}