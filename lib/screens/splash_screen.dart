import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:spectra/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/images/splashscreenbg.png",
              fit: BoxFit.cover,
            ),
          ),

          Container(
            color: Colors.white.withOpacity(0.1),
          ),

          // 🔥 shifted upward
          Align(
            alignment: const Alignment(0, -0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Welcome to",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Poly",
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),

                  const SizedBox(height: 4),

                  AnimatedTextKit(
                    repeatForever: true,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        "SPECTRA",
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                          fontSize: 52,
                          letterSpacing: 1.5,
                          color: Color(0xFF1E3A5F),
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Smart Presence Evaluation\nand\nClassroom Tracking Recognition Architecture",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Poly",
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SwipeButton(
                    onComplete: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeButton extends StatefulWidget {
  final VoidCallback onComplete;

  const SwipeButton({super.key, required this.onComplete});

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _position = 12;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 56;

    double progress = (_position / (width - 70)).clamp(0.0, 1.0);
    double textOpacity = 1 - progress;

    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Color(0xFF1E3A5F)),
        // 🔥 clean shadow added
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E3A5F).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: textOpacity,
            child: Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Swipe to Get Started >>",
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _position,
            top: 10,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _position += details.delta.dx;
                  if (_position < 12) _position = 12;
                  if (_position > width - 70) _position = width - 70;
                });
              },
              onHorizontalDragEnd: (_) {
                if (_position > width * 0.6) {
                  setState(() {
                    _position = width - 70;
                  });

                  Future.delayed(const Duration(milliseconds: 200), () {
                    widget.onComplete();
                  });
                } else {
                  setState(() {
                    _position = 12;
                  });
                }
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A5F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}