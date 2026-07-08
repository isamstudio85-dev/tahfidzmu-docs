import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_role.dart';
import '../services/firebase_service.dart';
import '../services/login_preferences_service.dart';

mixin AuthMixin on ChangeNotifier {
  final FirebaseService firebase = FirebaseService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  UserRole? currentRole;
  String? linkedSantriId;
  String? linkedMusyrifId;
  String? currentUserId;
  String? pesantrenId;
  String? loginError;

  bool get isLoggedIn => currentRole != null;
  bool get isSuperAdmin => currentRole == UserRole.superAdmin;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isMusyrif => currentRole == UserRole.musyrif;
  bool get isOrangTua => currentRole == UserRole.orangTua;
  bool get isPengawas => currentRole == UserRole.pengawas;

  void setLoginInfo(UserRole role, {String? linkedSantriId, String? linkedMusyrifId, String? userId, String? pesantrenId}) {
    currentRole = role;
    this.linkedSantriId = linkedSantriId;
    this.linkedMusyrifId = linkedMusyrifId;
    currentUserId = userId;
    this.pesantrenId = pesantrenId;
    notifyListeners();
  }

  UserRole? roleFromString(String role) {
    switch (role) {
      case 'superAdmin': return UserRole.superAdmin;
      case 'admin': return UserRole.admin;
      case 'musyrif': return UserRole.musyrif;
      case 'orangTua': return UserRole.orangTua;
      case 'pengawas': return UserRole.pengawas;
      default: return null;
    }
  }

  Future<void> performLogout() async {
    await firebase.signOut();
    await LoginPreferencesService.clearLastCredentials();
    currentRole = null;
    currentUserId = null;
    linkedSantriId = null;
    linkedMusyrifId = null;
    pesantrenId = null;
    notifyListeners();
  }
}
