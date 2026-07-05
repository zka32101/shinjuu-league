import 'package:flutter/material.dart';

/// ボタンタップ領域は 44pt 以上を必ず確保する（UI/UXクオリティ基準）
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          );

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(onPressed: isLoading ? null : onPressed, child: child)
          : OutlinedButton(onPressed: isLoading ? null : onPressed, child: child),
    );
  }
}
