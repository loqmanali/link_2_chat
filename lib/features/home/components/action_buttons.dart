import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/config/app_theme.dart';

class ActionButtons extends HookWidget {
  final VoidCallback onWhatsAppPressed;
  final VoidCallback onTelegramPressed;
  final VoidCallback onQrPressed;
  final bool isEnabled;

  const ActionButtons({
    super.key,
    required this.onWhatsAppPressed,
    required this.onTelegramPressed,
    required this.onQrPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPlatformButton(
                  icon: Icons.message_rounded,
                  label: 'WhatsApp',
                  onPressed: isEnabled ? onWhatsAppPressed : null,
                  color: AppTheme.whatsappColor,
                  disabledColor: AppTheme.whatsappColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlatformButton(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  onPressed: isEnabled ? onTelegramPressed : null,
                  color: AppTheme.telegramColor,
                  disabledColor: AppTheme.telegramColor.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQrButton(onPressed: isEnabled ? onQrPressed : null),
        ],
      ),
    );
  }

  Widget _buildPlatformButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required Color disabledColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : disabledColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: onPressed != null ? 2 : 0,
        shadowColor:
            onPressed != null ? color.withOpacity(0.4) : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrButton({required VoidCallback? onPressed}) {
    final isDisabled = onPressed == null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow:
            onPressed != null
                ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDisabled
                  ? AppTheme.primaryColor.withOpacity(0.4)
                  : AppTheme.primaryColor,
          side: BorderSide(
            color:
                isDisabled
                    ? AppTheme.primaryColor.withOpacity(0.4)
                    : AppTheme.primaryColor,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDisabled ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Generate QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
