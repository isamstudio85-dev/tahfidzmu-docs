import 'package:flutter/material.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

/// Widget loading dengan animasi smooth untuk indikator proses data
class LoadingIndicator extends StatefulWidget {
  final String? message;
  final double size;

  const LoadingIndicator({this.message, this.size = 50, super.key});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      width: 3,
                    ),
                  ),
                ),
              ),
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border(
                      top: BorderSide(color: AppTheme.primaryGreen, width: 3),
                      right: BorderSide(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      bottom: const BorderSide(
                        color: Colors.transparent,
                        width: 3,
                      ),
                      left: const BorderSide(
                        color: Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Loading overlay untuk full screen loading (dialog)
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({this.message = 'Memproses...', super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(children: [LoadingIndicator(message: message)]),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk placeholder saat data belum dimuat (lazy loading)
class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    this.height = 80,
    this.width,
    this.borderRadius,
    super.key,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Show loading dialog
void showLoadingDialog(
  BuildContext context, {
  String message = 'Memproses...',
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => LoadingOverlay(message: message),
  );
}

/// Hide loading dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.pop(context);
}
