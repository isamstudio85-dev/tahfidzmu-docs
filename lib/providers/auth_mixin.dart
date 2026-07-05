import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_role.dart';
import '../services/firebase_service.dart';

mixin AuthMixin on ChangeNotifier {
  final FirebaseService firebase = FirebaseService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  UserRole? currentRole;
  String? linkedSantriId;
  String? linkedMusyrifId;
  String? currentUserId;

  bool get isLoggedIn => currentRole != null;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isMusyrif => currentRole == UserRole.musyrif;
  bool get isOrangTua => currentRole == UserRole.orangTua;

  void setLoginInfo(UserRole role, {String? linkedSantriId, String? linkedMusyrifId, String? userId}) {
    currentRole = role;
    this.linkedSantriId = linkedSantriId;
    this.linkedMusyrifId = linkedMusyrifId;
    currentUserId = userId;
    notifyListeners();
  }

  UserRole? roleFromString(String role) {
    switch (role) {
      case 'admin': return UserRole.admin;
      case 'musyrif': return UserRole.musyrif;
      case 'orangTua': return UserRole.orangTua;
      default: return null;
    }
  }

  Future<void> performLogout() async {
    await firebase.signOut();
    currentRole = null;
    currentUserId = null;
    linkedSantriId = null;
    linkedMusyrifId = null;
    notifyListeners();
  }
}
