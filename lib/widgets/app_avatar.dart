import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final diameter = radius * 2;

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

    // Local file path (from image_picker) — highest priority
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipOval(
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

    // Bundled asset image
    if (imageAsset != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(imageAsset!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // Network avatar from DiceBear
    return CachedNetworkImage(
      imageUrl: avatarUrl(name, size: (radius * 2).round()),
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: diameter * 0.5,
          height: diameter * 0.5,
          child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
        ),
      ),
      errorWidget: (context, url, error) => fallback,
      width: diameter,
      height: diameter,
    );
  }
}
