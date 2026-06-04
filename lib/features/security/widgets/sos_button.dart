import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key, this.onActivated});

  final VoidCallback? onActivated;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isHolding = false;

  static const _holdDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.heavyImpact();
          widget.onActivated?.call();
          _reset();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _progressController.forward(from: 0);
  }

  void _reset() {
    _progressController.reset();
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _reset(),
      onTapCancel: _reset,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: _progressController.value,
                  strokeWidth: 5,
                  color: Colors.red.shade300,
                  backgroundColor: Colors.red.shade100,
                ),
              ),
              // Tombol utama
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _isHolding ? Colors.red.shade400 : Colors.red.shade600,
                      _isHolding ? Colors.red.shade600 : Colors.red.shade800,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(_isHolding ? 0.5 : 0.3),
                      blurRadius: _isHolding ? 24 : 16,
                      spreadRadius: _isHolding ? 4 : 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SOS',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      '✳',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}