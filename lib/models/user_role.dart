import 'package:flutter/material.dart';

enum UserRole {
  admin,
  musyrif,
  orangTua;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.musyrif:
        return 'Musyrif';
      case UserRole.orangTua:
        return 'Orang Tua';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Kelola seluruh data & pengaturan sistem';
      case UserRole.musyrif:
        return 'Kelola hafalan santri binaan';
      case UserRole.orangTua:
        return 'Pantau perkembangan hafalan anak';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.musyrif:
        return Icons.menu_book_rounded;
      case UserRole.orangTua:
        return Icons.family_restroom_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFF1565C0);
      case UserRole.musyrif:
        return const Color(0xFF2E7D32);
      case UserRole.orangTua:
        return const Color(0xFF7B1FA2);
    }
  }

  String get storedKey {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.musyrif:
        return 'musyrif';
      case UserRole.orangTua:
        return 'orangTua';
    }
  }

  static UserRole? fromKey(String? key) {
    switch (key) {
      case 'admin':
        return UserRole.admin;
      case 'musyrif':
        return UserRole.musyrif;
      case 'orangTua':
        return UserRole.orangTua;
      default:
        return null;
    }
  }
}
