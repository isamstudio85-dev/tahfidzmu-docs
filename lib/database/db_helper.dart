import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-based authentication helper.
class DbHelper {
  DbHelper._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'tahfidz_auth.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        linked_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await _insertDefaultAdmin(db);
  }

  static Future<void> _insertDefaultAdmin(Database db) async {
    await db.insert('users', {
      'id': 'admin_default',
      'username': 'admin',
      'password_hash': _hash('admin123'),
      'role': 'admin',
      'linked_id': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Verify credentials.
  static Future<Map<String, Object?>?> authenticate(String username, String password) async {
    // 1. Try normal normalization (e.g. 'admin')
    var result = await _performAuth(_normalizeUsername(username), password);
    if (result != null) return result;

    // 2. Try digit-only normalization (e.g. 'TH-2024-001' -> '2024001')
    final numeric = onlyDigits(username);
    if (numeric.isNotEmpty && numeric != username) {
      result = await _performAuth(numeric, password);
      if (result != null) return result;
    }
    return null;
  }

  static Future<Map<String, Object?>?> _performAuth(String user, String pass) async {
    try {
      final db = await database;
      final rows = await db.query('users', where: 'username = ? AND password_hash = ?', whereArgs: [user, _hash(pass)]);
      return rows.isNotEmpty ? rows.first : null;
    } catch (_) { return null; }
  }

  static Future<void> upsertUser({required String id, required String username, required String password, required String role, String? linkedId}) async {
    try {
      final db = await database;
      await db.insert('users', {
        'id': id,
        'username': _normalizeUsername(username),
        'password_hash': _hash(password),
        'role': role,
        'linked_id': linkedId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  static Future<void> deleteUserByLinkedId(String linkedId) async {
    final db = await database;
    await db.delete('users', where: 'linked_id = ?', whereArgs: [linkedId]);
  }

  static Future<void> clearAllNonAdminUsers() async {
    final db = await database;
    await db.delete('users', where: 'role != ?', whereArgs: ['admin']);
  }

  static Future<bool> resetPassword(String userId, String newPassword) async {
    final db = await database;
    final rows = await db.update('users', {'password_hash': _hash(newPassword)}, where: 'id = ?', whereArgs: [userId]);
    return rows > 0;
  }

  static Future<bool> changeOwnPassword(String username, String oldPassword, String newPassword) async {
    final user = await authenticate(username, oldPassword);
    if (user == null) return false;
    return resetPassword(user['id'] as String, newPassword);
  }

  static Future<Map<String, Object?>?> getUserByLinkedId(String linkedId) async {
    final db = await database;
    final rows = await db.query('users', where: 'linked_id = ?', whereArgs: [linkedId]);
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<Map<String, Object?>?> getUserById(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  static String onlyDigits(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\D+'), '');
  }

  static String makeUsername(String? primary, String? fallbackName) {
    final digits = onlyDigits(primary);
    if (digits.isNotEmpty) return digits;
    final src = fallbackName ?? 'user';
    return src.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9._\-]'), '');
  }

  static String buildDemoCredentialValue(String? primary, String? fallback) {
    final digits = onlyDigits(primary);
    if (digits.isNotEmpty) return digits;
    final fallbackDigits = onlyDigits(fallback);
    return fallbackDigits.isNotEmpty ? fallbackDigits : '1234';
  }

  static String _normalizeUsername(String username) => username.trim().toLowerCase();
}
