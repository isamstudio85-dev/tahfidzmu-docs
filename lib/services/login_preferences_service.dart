import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LastLoginCredentials {
  final String? pesantrenId;
  final String username;
  final String password;

  const LastLoginCredentials({
    this.pesantrenId,
    required this.username,
    required this.password,
  });
}

class SavedAccount {
  final String? pesantrenId;
  final String username;
  final String password;
  final String displayName;
  final String? photoPath;
  final String role;
  final String? linkedId;

  const SavedAccount({
    this.pesantrenId,
    required this.username,
    required this.password,
    required this.displayName,
    this.photoPath,
    required this.role,
    this.linkedId,
  });

  Map<String, dynamic> toJson() => {
    'pesantrenId': pesantrenId,
    'username': username,
    'password': password,
    'displayName': displayName,
    'photoPath': photoPath,
    'role': role,
    'linkedId': linkedId,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    pesantrenId: json['pesantrenId'] as String?,
    username: json['username'] as String,
    password: json['password'] as String,
    displayName: json['displayName'] as String,
    photoPath: json['photoPath'] as String?,
    role: json['role'] as String,
    linkedId: json['linkedId'] as String?,
  );
}

class LoginPreferencesService {
  static const _pesantrenIdKey = 'last_login_pesantren_id';
  static const _usernameKey = 'last_login_username';
  static const _passwordKey = 'last_login_password';
  static const _savedAccountsKey = 'saved_accounts_list';

  static Future<void> saveLastCredentials(
    String? pesantrenId,
    String username,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (pesantrenId != null) {
      await prefs.setString(_pesantrenIdKey, pesantrenId);
    } else {
      await prefs.remove(_pesantrenIdKey);
    }
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  static Future<LastLoginCredentials?> loadLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final pesantrenId = prefs.getString(_pesantrenIdKey);
    final username = prefs.getString(_usernameKey);
    final password = prefs.getString(_passwordKey);
    if (username == null || password == null) return null;
    return LastLoginCredentials(
      pesantrenId: pesantrenId,
      username: username,
      password: password,
    );
  }

  static Future<void> clearLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pesantrenIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }

  // ── Multi-Account Switcher Helpers ─────────────────────────────────────

  static Future<void> saveAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAccounts();
    // Remove duplicate if same username + pesantren
    list.removeWhere((a) => a.username == account.username && a.pesantrenId == account.pesantrenId);
    list.add(account);
    final jsonList = list.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_savedAccountsKey, jsonList);
  }

  static Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_savedAccountsKey);
    if (jsonList == null) return [];
    try {
      return jsonList.map((j) => SavedAccount.fromJson(jsonDecode(j))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> removeAccount(String username, String? pesantrenId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAccounts();
    list.removeWhere((a) => a.username == username && a.pesantrenId == pesantrenId);
    final jsonList = list.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_savedAccountsKey, jsonList);
  }

  static Future<void> clearAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedAccountsKey);
  }
}
