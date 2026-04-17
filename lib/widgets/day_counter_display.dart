import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated display for the total day count since the Churban.
class DayCounterDisplay extends StatefulWidget {
  final int totalDays;
  final Color accentColor;
  final bool isHebrew;

  const DayCounterDisplay({
    super.key,
    required this.totalDays,
    required this.accentColor,
    required this.isHebrew,
  });

  @override
  State<DayCounterDisplay> createState() => _DayCounterDisplayState();
}

class _DayCounterDisplayState extends State<DayCounterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _countAnimation = IntTween(
      begin: 0,
      end: widget.totalDays,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main number
        AnimatedBuilder(
          animation: _countAnimation,
          builder: (context, child) {
            return Text(
              _formatNumber(_countAnimation.value),
              style: GoogleFonts.assistant(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                height: 1,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.accentColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Text(
            widget.isHebrew ? 'ימים' : 'DAYS',
            style: GoogleFonts.assistant(
              color: widget.accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }
}
