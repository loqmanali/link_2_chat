import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/config/app_theme.dart';

class StatsCounter extends HookWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color? color;

  const StatsCounter({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppTheme.primaryColor;
    final animatedCount = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    final progressAnimation = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    useEffect(() {
      animatedCount.forward(from: 0);
      progressAnimation.forward(from: 0);
      return null;
    }, [count]);

    // Calculate progress percentage (for demo purposes)
    final progressPercentage = math.min(1.0, count / 10); // Cap at 100%

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, displayColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: displayColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: displayColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: progressAnimation.value * progressPercentage,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animatedCount,
                    builder: (context, child) {
                      final value = (count * animatedCount.value).round();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: displayColor,
                            ),
                          ),
                          Text(
                            '${(progressPercentage * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressAnimation.value * progressPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(displayColor),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}
