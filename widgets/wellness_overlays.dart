import 'package:flutter/material.dart';

// 1. MINDFUL BREATHING OVERLAY (POLISHED & CENTERED)
class MindfulBreathingOverlay extends StatefulWidget {
  const MindfulBreathingOverlay({super.key});

  @override
  State<MindfulBreathingOverlay> createState() => _MindfulBreathingOverlayState();
}

class _MindfulBreathingOverlayState extends State<MindfulBreathingOverlay> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _progressController;

  String _instruction = "Ready...";
  int _currentCycle = 0;
  final int _maxCycles = 4;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 4));

    _circleController.addStatusListener((status) {
      if (_isFinished) return;

      if (status == AnimationStatus.completed) {
        setState(() => _instruction = "Hold");
        _progressController.duration = const Duration(seconds: 7);
        _progressController.forward(from: 0);

        Future.delayed(const Duration(seconds: 7), () {
          if (mounted && !_isFinished) {
            setState(() => _instruction = "Exhale");
            _circleController.duration = const Duration(seconds: 8);
            _circleController.reverse();

            _progressController.duration = const Duration(seconds: 8);
            _progressController.forward(from: 0);
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        _currentCycle++;
        if (_currentCycle >= _maxCycles) {
          _finishExercise();
        } else {
          setState(() => _instruction = "Inhale");
          _circleController.duration = const Duration(seconds: 4);
          _circleController.forward();

          _progressController.duration = const Duration(seconds: 4);
          _progressController.forward(from: 0);
        }
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _instruction = "Inhale");
        _circleController.forward();
        _progressController.forward(from: 0);
      }
    });
  }

  void _finishExercise() {
    setState(() {
      _isFinished = true;
      _instruction = "Complete!";
    });
    _progressController.stop();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    // FIX: Added SizedBox(width: double.infinity) to force centering inside the ScrollView
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                                _isFinished ? 'Great job.' : 'Cycle ${_currentCycle + 1} of $_maxCycles',
                                style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 300,
                                width: 300,
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _circleController,
                                    builder: (context, child) {
                                      double size = 120 + (_circleController.value * 150);
                                      return Container(
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isFinished ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.tealAccent.withValues(alpha: 0.3),
                                          border: Border.all(color: _isFinished ? Colors.greenAccent : Colors.tealAccent, width: 2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _instruction,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: _isFinished ? Colors.greenAccent : Colors.tealAccent,
                                              fontSize: _isFinished ? 32 : 28,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              if (!_isFinished)
                                SizedBox(
                                  width: 150,
                                  child: AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (context, child) {
                                        return LinearProgressIndicator(
                                          value: _progressController.value,
                                          backgroundColor: Colors.white12,
                                          color: Colors.tealAccent,
                                          borderRadius: BorderRadius.circular(10),
                                          minHeight: 6,
                                        );
                                      }
                                  ),
                                ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFinished ? Colors.green.shade700 : Colors.white24,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(_isFinished ? 'Return to Study' : 'End Early', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
        ),
      ),
    );
  }
}

// 2. HYDRATION OVERLAY
class HydrationOverlay extends StatelessWidget {
  const HydrationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(Icons.water_drop, size: 100, color: Colors.lightBlueAccent),
                  );
                }
            ),
            const SizedBox(height: 24),
            const Text('Time to Hydrate!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Drinking water boosts brain performance by 14%. Take a minute to grab a glass of water before continuing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Hydrated & Ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
// 3. GUIDED STRETCH OVERLAY (STICK FIGURE ENGINE)
class StretchOverlay extends StatefulWidget {
  const StretchOverlay({super.key});

  @override
  State<StretchOverlay> createState() => _StretchOverlayState();
}

class _StretchOverlayState extends State<StretchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _moveController;
  int _timeLeft = 60;
  bool _isFinished = false;

  final List<String> _stretchInstructions = [
    "Neck Rolls",
    "Shoulder Shrugs",
    "Overhead Reach",
    "Torso Twists"
  ];

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _moveController.repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        _startTimer();
      } else {
        setState(() {
          _isFinished = true;
          _moveController.stop();
        });
      }
    });
  }

  int get _currentStretchPhase {
    if (_timeLeft > 45) return 0;
    if (_timeLeft > 30) return 1;
    if (_timeLeft > 15) return 2;
    return 3;
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3142),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    // FIX: Added SizedBox(width: double.infinity) here as well!
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                                _isFinished ? 'Routine Complete' : '60-Second Stretch',
                                style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 250,
                                width: 250,
                                child: AnimatedBuilder(
                                    animation: _moveController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: StickFigurePainter(
                                          phase: _currentStretchPhase,
                                          animValue: _moveController.value,
                                        ),
                                      );
                                    }
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                _isFinished ? 'Great work.' : _stretchInstructions[_currentStretchPhase],
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              if (!_isFinished)
                                Text(
                                  '00:${_timeLeft.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 32, fontWeight: FontWeight.w900),
                                )
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFinished ? Colors.green.shade600 : Colors.white24,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(_isFinished ? 'Return to Study' : 'End Early', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
        ),
      ),
    );
  }
}

// The Custom Painter Math
class StickFigurePainter extends CustomPainter {
  final int phase;
  final double animValue;

  StickFigurePainter({required this.phase, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    Offset headCenter = Offset(center.dx, center.dy - 60);
    Offset shoulder = Offset(center.dx, center.dy - 30);
    Offset hips = Offset(center.dx, center.dy + 40);
    Offset leftFoot = Offset(center.dx - 30, center.dy + 100);
    Offset rightFoot = Offset(center.dx + 30, center.dy + 100);

    Offset leftHand = Offset.zero;
    Offset rightHand = Offset.zero;

    if (phase == 0) {
      double headOffset = (animValue - 0.5) * 30;
      headCenter = Offset(center.dx + headOffset, center.dy - 60);
      leftHand = Offset(center.dx - 40, center.dy + 10);
      rightHand = Offset(center.dx + 40, center.dy + 10);
    }
    else if (phase == 1) {
      double shrug = animValue * 20;
      shoulder = Offset(center.dx, center.dy - 30 - shrug);
      leftHand = Offset(center.dx - 40, center.dy + 10 - shrug);
      rightHand = Offset(center.dx + 40, center.dy + 10 - shrug);
    }
    else if (phase == 2) {
      double swing = animValue * 80;
      leftHand = Offset(center.dx - 40, center.dy - 20 - swing);
      rightHand = Offset(center.dx + 40, center.dy - 20 - swing);
    }
    else if (phase == 3) {
      double twist = (animValue - 0.5) * 80;
      leftHand = Offset(center.dx - 50 + twist, center.dy);
      rightHand = Offset(center.dx + 50 + twist, center.dy);
    }

    canvas.drawLine(shoulder, hips, paint);
    canvas.drawLine(hips, leftFoot, paint);
    canvas.drawLine(hips, rightFoot, paint);
    canvas.drawLine(shoulder, leftHand, paint);
    canvas.drawLine(shoulder, rightHand, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, 18, paint);
  }

  @override
  bool shouldRepaint(covariant StickFigurePainter oldDelegate) => true;
}
