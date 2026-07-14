import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/reward_system.dart';

/// Generates a DiceBear avatar URL seeded by the person's name.
/// Each name always maps to the same avatar (deterministic).
/// Uses the free DiceBear Avataaars Neutral style — no API key needed.
String avatarUrl(String name, {int size = 128}) {
  final seed = Uri.encodeComponent(name.trim());
  return 'https://api.dicebear.com/9.x/avataaars-neutral/png'
      '?seed=$seed'
      '&size=$size'
      '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf'
      '&backgroundType=gradientLinear';
}

/// A circular avatar widget that:
/// 1. Loads a DiceBear AI-generated image from the network
/// 2. Shows initials as fallback while loading or on error
/// 3. Optionally shows a local [imageAsset] (e.g., actual photo stored in assets/)
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.imagePath,
    this.imageAsset,
    this.backgroundColor,
    this.foregroundColor,
    this.activeFrame,
    this.streakDays = 0,
  });

  /// Person's name — used to seed the AI avatar and derive initials.
  final String name;

  /// Radius of the circular avatar.
  final double radius;

  /// Local file path from image_picker (highest priority).
  final String? imagePath;

  /// Optional local asset path (e.g. 'assets/images/santri_001.jpg').
  final String? imageAsset;

  /// Background color for the fallback initials avatar.
  final Color? backgroundColor;

  /// Text color for the fallback initials avatar.
  final Color? foregroundColor;

  /// Virtual frame ID to draw around the avatar.
  final String? activeFrame;

  /// Streak days of memorization (shows fire overlay if >= 7).
  final int streakDays;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.lightGreen;
    final fgColor = foregroundColor ?? AppTheme.darkGreen;
    final frameColor = RewardSystem.getFrameColor(activeFrame);

    Widget avatar;

    Widget fallback = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );

    // Handle Image (Cloud URL or Local File)
    if (imagePath != null && imagePath!.isNotEmpty) {
      final isUrl = imagePath!.startsWith('http');
      
      if (isUrl) {
        avatar = CachedNetworkImage(
          imageUrl: imagePath!,
          imageBuilder: (context, imageProvider) => CircleAvatar(radius: radius, backgroundImage: imageProvider),
          placeholder: (context, url) => CircleAvatar(radius: radius, backgroundColor: bgColor, child: const CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => fallback,
        );
      } else {
        avatar = ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
        );
      }
    } else if (imageAsset != null) {
      // Bundled asset image
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(imageAsset!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    } else {
      // Fallback to initials with dynamic themed background (clean & premium)
      avatar = fallback;
    }

    final showFire = streakDays >= 7;

    Widget renderedAvatar = frameColor == null 
        ? avatar 
        : Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: radius * 2 + 8,
                height: radius * 2 + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: frameColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // The Frame
              Container(
                width: radius * 2 + 6,
                height: radius * 2 + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: frameColor, width: 3),
                ),
              ),
              avatar,
            ],
          );

    if (!showFire) return renderedAvatar;

    // Wrap with Fire / Streak Status overlay
    return Stack(
      clipBehavior: Clip.none,
      children: [
        renderedAvatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade500, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.amber,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}
