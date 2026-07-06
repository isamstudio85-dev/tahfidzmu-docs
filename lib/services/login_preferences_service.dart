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

class LoginPreferencesService {
  static const _pesantrenIdKey = 'last_login_pesantren_id';
  static const _usernameKey = 'last_login_username';
  static const _passwordKey = 'last_login_password';

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
}
