import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/services/haptic_service.dart';

/// ボタンタップ領域は 44pt 以上を必ず確保する（UI/UXクオリティ基準）。
/// タップ時にバウンス縮小 + ハプティクス + SE を伴う。
class CustomButton extends StatefulWidget {
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 0.06,
  );

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    _controller.forward();
  }

  void _onTapEnd() {
    if (_controller.isAnimating || _controller.value > 0) {
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (!_isEnabled) return;
    HapticService.onButtonTap();
    unawaited(AudioService().playButtonTapSe());
    widget.onPressed!();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 20), const SizedBox(width: 8)],
              Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _onTapEnd(),
      onTapCancel: _onTapEnd,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, buttonChild) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: buttonChild);
        },
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: IgnorePointer(
            child: widget.isPrimary
                ? ElevatedButton(onPressed: _isEnabled ? () {} : null, child: child)
                : OutlinedButton(onPressed: _isEnabled ? () {} : null, child: child),
          ),
        ),
      ),
    );
  }
}
