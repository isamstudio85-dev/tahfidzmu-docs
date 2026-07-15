import 'package:flutter/material.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/reward_system.dart';

class UserAvatarWithFrame extends StatelessWidget {
  final String? photoPath;
  final String name;
  final String? frameId;
  final double size;
  final Color? fallbackColor;

  const UserAvatarWithFrame({
    super.key,
    this.photoPath,
    required this.name,
    this.frameId,
    this.size = 48,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final frameColor = RewardSystem.getFrameColor(frameId);
    final hasFrame = frameColor != null;
    final themeColor = fallbackColor ?? AppTheme.primaryGreen;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frame Glow Effect (if has frame)
          if (hasFrame)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: frameColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          
          // The Avatar
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              image: (photoPath?.isNotEmpty ?? false)
                  ? DecorationImage(image: NetworkImage(photoPath!), fit: BoxFit.cover)
                  : null,
              border: Border.all(
                color: hasFrame ? frameColor : themeColor.withValues(alpha: 0.2),
                width: hasFrame ? 2 : 1,
              ),
            ),
            child: (photoPath?.isEmpty ?? true)
                ? Center(
                    child: Text(
                      name.isEmpty ? "?" : name[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasFrame ? frameColor : themeColor,
                        fontSize: size * 0.35,
                      ),
                    ),
                  )
                : null,
          ),
          
          // Extra Frame Ornament (Visual decoration)
          if (hasFrame)
            CustomPaint(
              size: Size(size, size),
              painter: FramePainter(frameColor),
            ),
        ],
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final Color color;
  FramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Drawing simple corner accents to make it look "gamey"
    final double center = size.width / 2;
    final double radius = size.width / 2;

    // Top ornament
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      -1.2, 0.4, false, paint,
    );
    
    // Bottom ornament
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      1.9, 0.4, false, paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
