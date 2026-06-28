import 'package:shared_preferences/shared_preferences.dart';

class LastLoginCredentials {
  final String username;
  final String password;

  const LastLoginCredentials({required this.username, required this.password});
}

class LoginPreferencesService {
  static const _usernameKey = 'last_login_username';
  static const _passwordKey = 'last_login_password';

  static Future<void> saveLastCredentials(
    String username,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  static Future<LastLoginCredentials?> loadLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final password = prefs.getString(_passwordKey);
    if (username == null || password == null) return null;
    return LastLoginCredentials(username: username, password: password);
  }

  static Future<void> clearLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }
}
