import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-based authentication helper.
/// Stores only the users table — all other app data stays in SharedPreferences.
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
    // Seed default admin account
    await db.insert('users', {
      'id': 'admin_default',
      'username': 'admin',
      'password_hash': _hash('admin123'),
      'role': 'admin',
      'linked_id': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Crypto ──────────────────────────────────────────────────────────────────

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// Verify credentials. Returns user row map, or null if invalid.
  static Future<Map<String, Object?>?> authenticate(
    String username,
    String password,
  ) async {
    try {
      final db = await database;
      final rows = await db.query(
        'users',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [_normalizeUsername(username), _hash(password)],
      );
      return rows.isNotEmpty ? rows.first : null;
    } catch (_) {
      return null;
    }
  }

  // ── User CRUD ────────────────────────────────────────────────────────────────

  /// Insert a user. Silently ignores duplicate usernames.
  static Future<void> upsertUser({
    required String id,
    required String username,
    required String password,
    required String role,
    String? linkedId,
  }) async {
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
    try {
      final db = await database;
      await db.delete('users', where: 'linked_id = ?', whereArgs: [linkedId]);
    } catch (_) {}
  }

  /// Admin resets password for any user (by DB id).
  static Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      final db = await database;
      final rows = await db.update(
        'users',
        {'password_hash': _hash(newPassword)},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return rows > 0;
    } catch (_) {
      return false;
    }
  }

  /// User changes their own password — requires old password verification.
  static Future<bool> changeOwnPassword(
    String username,
    String oldPassword,
    String newPassword,
  ) async {
    final user = await authenticate(username, oldPassword);
    if (user == null) return false;
    return resetPassword(user['id'] as String, newPassword);
  }

  static Future<Map<String, Object?>?> getUserByLinkedId(
    String linkedId,
  ) async {
    try {
      final db = await database;
      final rows = await db.query(
        'users',
        where: 'linked_id = ?',
        whereArgs: [linkedId],
      );
      return rows.isNotEmpty ? rows.first : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, Object?>?> getUserById(String id) async {
    try {
      final db = await database;
      final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
      return rows.isNotEmpty ? rows.first : null;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Build a clean username from NIP/NIS (primary) or nama (fallback).
  static String makeUsername(String? primary, String? fallbackName) {
    final src = primary?.isNotEmpty == true ? primary! : fallbackName ?? 'user';
    // Keep alphanumeric, dot, underscore, hyphen; replace spaces → _
    final clean = src
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9._\-]'), '');
    final trimmed = clean.isEmpty ? 'user' : clean;
    return trimmed.length > 30 ? trimmed.substring(0, 30) : trimmed;
  }

  /// Build a short numeric credential for demo accounts.
  static String buildDemoCredentialValue(String? primary, String? fallback) {
    final source = primary?.isNotEmpty == true ? primary! : fallback ?? '0';
    final digits = source.replaceAll(RegExp(r'\D+'), '');
    if (digits.isNotEmpty) {
      final short = digits.length > 4
          ? digits.substring(digits.length - 4)
          : digits;
      return short.padLeft(4, '0');
    }
    return '1234';
  }

  static String _normalizeUsername(String username) =>
      username.trim().toLowerCase();
}
