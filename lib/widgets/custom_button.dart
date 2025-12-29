import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final ButtonVariant variant;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.variant = ButtonVariant.primary, required Widget child,
  }) : super(key: key);

  Color _getBackgroundColor(ButtonVariant variant, bool isEnabled) {
    if (!isEnabled) return Colors.grey.shade300;
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.blue;
      case ButtonVariant.secondary:
        return Colors.grey.shade800;
      case ButtonVariant.danger:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final backgroundColor = _getBackgroundColor(variant, isEnabled);

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}
