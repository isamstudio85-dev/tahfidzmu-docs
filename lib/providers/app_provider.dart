import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/error_mark.dart';
import '../models/surah_model.dart';
import '../models/setoran_continuation.dart';
import '../models/user_role.dart';
import '../models/musyrif_data.dart';
import '../models/halaqah_data.dart';
import '../models/kelas_data.dart';
import '../models/pesantren_info.dart';
import '../services/quran_service.dart';
import '../services/demo_data_service.dart';
import '../services/login_preferences_service.dart';
import '../utils/scoring_utils.dart';

class AppProvider extends ChangeNotifier {
  // ── Santri ──────────────────────────────────────────────────────────
  List<Santri> _santriList = [];
  List<Santri> get santriList => List.unmodifiable(_santriList);
  // ── Musyrif list ──────────────────────────────────────────────────────
  List<MusyrifData> _musyrifList = [];
  List<MusyrifData> get musyrifList => List.unmodifiable(_musyrifList);

  MusyrifData? getMusyrifById(String? id) {
    if (id == null) return null;
    try {
      return _musyrifList.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  void addMusyrif(MusyrifData m, {String? username, String? password}) {
    _musyrifList = [..._musyrifList, m];
    _saveMusyrifList();
    notifyListeners();
    final resolvedUsername = (username?.trim().isNotEmpty ?? false)
        ? username!.trim()
        : DbHelper.makeUsername(m.nip, m.nama);
    final resolvedPassword = (password?.trim().isNotEmpty ?? false)
        ? password!.trim()
        : DbHelper.buildDemoCredentialValue(m.nip, m.nama);
    DbHelper.upsertUser(
      id: 'musyrif_${m.id}',
      username: resolvedUsername,
      password: resolvedPassword,
      role: 'musyrif',
      linkedId: m.id,
    );
  }

  void updateMusyrifData(String id, MusyrifData updated) {
    _musyrifList = _musyrifList.map((m) => m.id == id ? updated : m).toList();
    _saveMusyrifList();
    notifyListeners();
  }

  void removeMusyrif(String id) {
    _musyrifList = _musyrifList.where((m) => m.id != id).toList();
    _saveMusyrifList();
    notifyListeners();
    DbHelper.deleteUserByLinkedId(id);
  }

  Future<void> _saveMusyrifList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'musyrif_list',
        jsonEncode(_musyrifList.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Halaqah list ──────────────────────────────────────────────────────
  List<HalaqahData> _halaqahList = [];
  List<HalaqahData> get halaqahList => List.unmodifiable(_halaqahList);

  HalaqahData? getHalaqahById(String? id) {
    if (id == null) return null;
    try {
      return _halaqahList.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Santri> getSantriByHalaqah(String halaqahId) =>
      _santriList.where((s) => s.halaqahId == halaqahId).toList();

  List<Santri> getSantriByMusyrif(String musyrifId) {
    final halaqahIds = _halaqahList
        .where((h) => h.musyrifId == musyrifId)
        .map((h) => h.id)
        .toSet();
    return _santriList.where((s) => halaqahIds.contains(s.halaqahId)).toList();
  }

  void addHalaqah(HalaqahData h) {
    _halaqahList = [..._halaqahList, h];
    _saveHalaqahList();
    notifyListeners();
  }

  void updateHalaqah(String id, HalaqahData updated) {
    _halaqahList = _halaqahList.map((h) => h.id == id ? updated : h).toList();
    _saveHalaqahList();
    notifyListeners();
  }

  void removeHalaqah(String id) {
    _halaqahList = _halaqahList.where((h) => h.id != id).toList();
    _saveHalaqahList();
    notifyListeners();
  }

  Future<void> _saveHalaqahList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'halaqah_list',
        jsonEncode(_halaqahList.map((h) => h.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Kelas list ────────────────────────────────────────────────────────
  List<KelasData> _kelasList = [];
  List<KelasData> get kelasList => List.unmodifiable(_kelasList);

  void addKelas(KelasData k) {
    _kelasList = [..._kelasList, k];
    _saveKelasList();
    notifyListeners();
  }

  void updateKelas(String id, KelasData updated) {
    _kelasList = _kelasList.map((k) => k.id == id ? updated : k).toList();
    _saveKelasList();
    notifyListeners();
  }

  void removeKelas(String id) {
    _kelasList = _kelasList.where((k) => k.id != id).toList();
    _saveKelasList();
    notifyListeners();
  }

  Future<void> _saveKelasList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kelas_list',
        jsonEncode(_kelasList.map((k) => k.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Surah list (for pickers) ──────────────────────────────────────────
  List<SurahInfo> _surahList = [];
  List<SurahInfo> get surahList => List.unmodifiable(_surahList);
  bool isSurahListLoading = false;
  String? surahListError;

  // ── Active session ─────────────────────────────────────────────────────
  Santri? activeSetoranSantri;
  SetoranType activeSetoranType = SetoranType.ziyadah;
  int activeSetoranSurahNumber = 1;
  String activeSetoranSurahName = '';
  String activeSetoranSurahEnglishName = '';
  int activeSetoranAyahStart = 1;
  int activeSetoranAyahEnd = 7;

  final Map<String, ErrorMark> _sessionErrors = {};
  Map<String, ErrorMark> get sessionErrors => Map.unmodifiable(_sessionErrors);

  // ── Auth / Session ─────────────────────────────────────────────────────
  UserRole? _currentRole;
  String? _linkedSantriId;
  String? _linkedMusyrifId;
  String? _currentUserId; // DB user id for password management
  UserRole? get currentRole => _currentRole;
  String? get linkedSantriId => _linkedSantriId;
  String? get linkedMusyrifId => _linkedMusyrifId;
  String? get currentUserId => _currentUserId;
  Santri? get linkedSantri =>
      _linkedSantriId != null ? getSantriById(_linkedSantriId!) : null;
  MusyrifData? get linkedMusyrif => getMusyrifById(_linkedMusyrifId);
  bool get isLoggedIn => _currentRole != null;
  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isMusyrif => _currentRole == UserRole.musyrif;
  bool get isOrangTua => _currentRole == UserRole.orangTua;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  void login(UserRole role, {String? linkedSantriId, String? linkedMusyrifId}) {
    _currentRole = role;
    _linkedSantriId = linkedSantriId;
    _linkedMusyrifId = linkedMusyrifId;
    _saveRole();
    notifyListeners();
  }

  /// Real authentication — returns true if credentials are valid.
  Future<bool> loginWithCredentials(String username, String password) async {
    final user = await DbHelper.authenticate(username, password);
    if (user == null) return false;
    final role = _roleFromString(user['role'] as String);
    if (role == null) return false;
    _currentUserId = user['id'] as String?;
    _currentRole = role;
    _linkedSantriId = role == UserRole.orangTua ? user['linked_id'] as String? : null;
    _linkedMusyrifId = role == UserRole.musyrif ? user['linked_id'] as String? : null;
    await LoginPreferencesService.saveLastCredentials(username, password);
    _saveRole();

    // If Admin logs in, ensure all user accounts are synced to the latest format
    if (role == UserRole.admin) {
      _seedUserAccounts();
    }

    notifyListeners();
    return true;
  }

  static UserRole? _roleFromString(String role) {
    switch (role) {
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

  /// Change own password — requires old password verification.
  Future<bool> changeOwnPassword(String oldPassword, String newPassword) async {
    if (_currentUserId == null) return false;
    final user = await DbHelper.getUserById(_currentUserId!);
    if (user == null) return false;
    return DbHelper.changeOwnPassword(
      user['username'] as String,
      oldPassword,
      newPassword,
    );
  }

  /// Admin resets a user's password to [newPassword].
  Future<bool> resetUserPassword(String userId, String newPassword) async {
    return DbHelper.resetPassword(userId, newPassword);
  }

  Future<bool> resetPasswordForLinkedId(
    String linkedId,
    String newPassword,
  ) async {
    final user = await DbHelper.getUserByLinkedId(linkedId);
    if (user == null) return false;
    return resetUserPassword(user['id'] as String, newPassword);
  }

  Future<void> logout() async {
    _currentRole = null;
    _currentUserId = null;
    await _saveRole();
    // Do not clear saved credentials here, so they can stay in the login fields
    notifyListeners();
  }

  Future<void> _saveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentRole != null) {
        await prefs.setString('current_role', _currentRole!.storedKey);
      } else {
        await prefs.remove('current_role');
      }
      if (_linkedSantriId != null) {
        await prefs.setString('linked_santri_id', _linkedSantriId!);
      } else {
        await prefs.remove('linked_santri_id');
      }
      if (_linkedMusyrifId != null) {
        await prefs.setString('linked_musyrif_id', _linkedMusyrifId!);
      } else {
        await prefs.remove('linked_musyrif_id');
      }
    } catch (_) {}
  }

  // ── Current surah for reader ──────────────────────────────────────────
  SurahDetail? currentSurah;
  bool isSurahLoading = false;
  String? surahLoadError;

  // ── App info ─────────────────────────────────────────────────────
  PesantrenInfo _pesantrenInfo = const PesantrenInfo(
    nama: 'Al-Furqon MBS Cibiuk',
    alamat: 'Jl. Pulobaru Desa Cibiuk Kaler Kec Cibiuk Garut',
    noTelp: '081289607738',
    email: 'info.alfurqonmbscibiuk@gmail.com',
  );
  PesantrenInfo get pesantrenInfo => _pesantrenInfo;
  // Backward-compat getter
  String get pesantrenName => _pesantrenInfo.nama;

  void updatePesantrenInfo(PesantrenInfo info) {
    _pesantrenInfo = info;
    _savePesantrenInfo();
    notifyListeners();
  }

  /// Backward-compat — only updates the name field.
  void updatePesantrenName(String name) {
    updatePesantrenInfo(_pesantrenInfo.copyWith(nama: name));
  }

  Future<void> _savePesantrenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pesantren_info',
        jsonEncode(_pesantrenInfo.toJson()),
      );
    } catch (_) {}
  }

  // ── Active hafalan modules ───────────────────────────────────────
  final Set<String> _activeModules = {'quran', 'hadits', 'tajwid', 'tahsin'};
  Set<String> get activeModules => Set.unmodifiable(_activeModules);

  bool isModuleActive(String key) => _activeModules.contains(key);

  void toggleModule(String key) {
    if (key == 'quran') return; // Al-Quran cannot be disabled
    if (_activeModules.contains(key)) {
      _activeModules.remove(key);
    } else {
      _activeModules.add(key);
    }
    _saveActiveModules();
    notifyListeners();
  }

  Future<void> _saveActiveModules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('active_modules', _activeModules.toList());
    } catch (_) {}
  }

  // -- Admin/Global profile ---------------------------------------------
  String _adminPhoto = '';
  String get adminPhoto => _adminPhoto;

  void updateAdminPhoto(String path) {
    _adminPhoto = path;
    _saveAdminPhoto();
    notifyListeners();
  }

  Future<void> _saveAdminPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_photo', _adminPhoto);
    } catch (_) {}
  }

  // -- Musyrif profile ---------------------------------------------------
  String _musyrif = '';
  String _lembaga = '';
  String _jabatan = '';
  String _nomorHp = '';
  String _musyrifPhoto = '';
  String get musyrif => _musyrif.isEmpty ? 'Musyrif' : _musyrif;
  String get lembaga => _lembaga.isEmpty ? 'Halaqah Tahfidz' : _lembaga;
  String get jabatan => _jabatan.isEmpty ? 'Musyrif Al-Quran' : _jabatan;
  String get nomorHp => _nomorHp;
  String get musyrifPhoto => _musyrifPhoto;

  void updateMusyrifInfo(
    String name,
    String lembagaName, {
    String jabatan = '',
    String nomorHp = '',
  }) {
    _musyrif = name;
    _lembaga = lembagaName;
    _jabatan = jabatan;
    _nomorHp = nomorHp;
    _saveMusyrif();
    notifyListeners();
  }

  void updateMusyrifPhoto(String path) {
    _musyrifPhoto = path;
    _saveMusyrif();
    notifyListeners();
  }

  void updateSantriPhoto(String santriId, String path) {
    _santriList = _santriList.map((s) {
      if (s.id == santriId) return s.copyWith(photoPath: path);
      return s;
    }).toList();
    _save();
    notifyListeners();
  }

  Future<void> _saveMusyrif() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('musyrif_name', _musyrif);
      await prefs.setString('musyrif_lembaga', _lembaga);
      await prefs.setString('musyrif_jabatan', _jabatan);
      await prefs.setString('musyrif_nomorhp', _nomorHp);
      await prefs.setString('musyrif_photo', _musyrifPhoto);
    } catch (_) {}
  }

  void resetAllData() {
    _santriList = [];
    _musyrifList = [];
    _halaqahList = [];
    _kelasList = [];
    _save();
    _saveMusyrifList();
    _saveHalaqahList();
    _saveKelasList();
    DbHelper.clearAllNonAdminUsers();
    notifyListeners();
  }

  AppProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    notifyListeners();

    try {
      await Future.wait<void>([_loadFromStorage(), _fetchSurahList()]);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ── Santri Management ─────────────────────────────────────────────────

  void addSantri(
    String name, {
    String? halaqahId,
    String? kelas,
    String? nis,
    String? email,
    String? jenisKelamin,
    String? namaOrangTua,
    String? namaAyah,
    String? namaIbu,
    String? nomorHpWali,
    String? targetHafalan,
    String? photoPath,
    List<int>? initialMemorizedJuz,
    String? username,
    String? password,
    // old-name aliases
    String? nik,
    String? namaOrtu,
    String? nomorOrtu,
  }) {
    _santriList = [
      ..._santriList,
      Santri(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        nis: (nis ?? nik)?.isEmpty ?? true ? null : (nis ?? nik),
        email: email,
        jenisKelamin: jenisKelamin,
        kelas: kelas,
        halaqahId: halaqahId,
        namaOrangTua: (namaOrangTua ?? namaOrtu)?.isEmpty ?? true
            ? null
            : (namaOrangTua ?? namaOrtu),
        namaAyah: (namaAyah ?? namaOrtu)?.isEmpty ?? true
            ? null
            : (namaAyah ?? namaOrtu),
        namaIbu: namaIbu?.isEmpty ?? true ? null : namaIbu,
        nomorHpWali: (nomorHpWali ?? nomorOrtu)?.isEmpty ?? true
            ? null
            : (nomorHpWali ?? nomorOrtu),
        targetHafalan: targetHafalan?.isEmpty ?? true ? null : targetHafalan,
        photoPath: photoPath,
        initialMemorizedJuz: initialMemorizedJuz ?? [],
      ),
    ];
    // Create orang tua login account when NIS is provided
    final resolvedNis = (nis ?? nik)?.isEmpty ?? true ? null : (nis ?? nik);
    final newSantri = _santriList.last;
    if (resolvedNis != null) {
      final resolvedUsername = (username?.trim().isNotEmpty ?? false)
          ? username!.trim()
          : DbHelper.onlyDigits(resolvedNis);
      final resolvedPassword = (password?.trim().isNotEmpty ?? false)
          ? password!.trim()
          : DbHelper.onlyDigits(resolvedNis);
      DbHelper.upsertUser(
        id: 'santri_${newSantri.id}',
        username: resolvedUsername,
        password: resolvedPassword,
        role: 'orangTua',
        linkedId: newSantri.id,
      );
    }
    _save();
    notifyListeners();
  }

  void updateSantriInfo(
    String santriId, {
    String? name,
    String? nis,
    String? email,
    String? jenisKelamin,
    String? halaqahId,
    String? kelas,
    String? namaOrangTua,
    String? namaAyah,
    String? namaIbu,
    String? nomorHpWali,
    String? targetHafalan,
    String? photoPath,
    String? status,
    List<int>? initialMemorizedJuz,
    // old-name aliases
    String? nik,
    String? namaOrtu,
    String? nomorOrtu,
  }) {
    _santriList = _santriList.map((s) {
      if (s.id != santriId) return s;
      return s.copyWith(
        name: name,
        nis: nis ?? nik,
        email: email,
        jenisKelamin: jenisKelamin,
        kelas: kelas,
        halaqahId: halaqahId,
        namaOrangTua: namaOrangTua ?? namaOrtu,
        namaAyah: namaAyah ?? namaOrtu,
        namaIbu: namaIbu,
        nomorHpWali: nomorHpWali ?? nomorOrtu,
        targetHafalan: targetHafalan,
        photoPath: photoPath,
        status: status,
        initialMemorizedJuz: initialMemorizedJuz,
      );
    }).toList();
    _save();
    notifyListeners();
  }

  void removeSantri(String santriId) {
    _santriList = _santriList.where((s) => s.id != santriId).toList();
    _save();
    notifyListeners();
    DbHelper.deleteUserByLinkedId(santriId);
  }

  Santri? getSantriById(String id) {
    try {
      return _santriList.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Setoran Session ──────────────────────────────────────────────────

  void startSetoranSession({
    required Santri santri,
    required SetoranType type,
    required SurahInfo surah,
    required int ayahStart,
    required int ayahEnd,
  }) {
    activeSetoranSantri = santri;
    activeSetoranType = type;
    activeSetoranSurahNumber = surah.number;
    activeSetoranSurahName = surah.name;
    activeSetoranSurahEnglishName = surah.englishName;
    activeSetoranAyahStart = ayahStart;
    activeSetoranAyahEnd = ayahEnd;
    _sessionErrors.clear();
    notifyListeners();
  }

  void toggleError({
    required int surahNumber,
    required int ayahNumber,
    required int wordIndex,
    required String word,
    required ErrorType errorType,
  }) {
    final key = ErrorMark.generateKey(surahNumber, ayahNumber, wordIndex);
    if (_sessionErrors.containsKey(key) &&
        _sessionErrors[key]!.errorType == errorType) {
      _sessionErrors.remove(key);
    } else {
      _sessionErrors[key] = ErrorMark(
        wordKey: key,
        errorType: errorType,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        word: word,
      );
    }
    notifyListeners();
  }

  void removeError(String wordKey) {
    _sessionErrors.remove(wordKey);
    notifyListeners();
  }

  void clearErrors() {
    _sessionErrors.clear();
    notifyListeners();
  }

  int get sessionTajwidCount => _sessionErrors.values
      .where((e) => e.errorType == ErrorType.tajwid)
      .length;

  int get sessionMakhrojCount => _sessionErrors.values
      .where((e) => e.errorType == ErrorType.makhroj)
      .length;

  /// Finalises the session, saves the record, and returns it.
  SetoranRecord completeSetoran(int fluencyRating) {
    final errors = _sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(
      errorMarks: errors,
      fluencyRating: fluencyRating,
    );

    final record = SetoranRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      santriId: activeSetoranSantri!.id,
      type: activeSetoranType,
      surahNumber: activeSetoranSurahNumber,
      surahName: activeSetoranSurahName,
      surahEnglishName: activeSetoranSurahEnglishName,
      ayahStart: activeSetoranAyahStart,
      ayahEnd: activeSetoranAyahEnd,
      errorMarks: errors,
      fluencyRating: fluencyRating,
      date: DateTime.now(),
      finalScore: score,
    );

    final idx = _santriList.indexWhere((s) => s.id == activeSetoranSantri!.id);
    if (idx != -1) {
      final s = _santriList[idx];
      _santriList[idx] = s.copyWith(
        setoranHistory: [...s.setoranHistory, record],
      );
    }

    _sessionErrors.clear();
    _save();
    notifyListeners();
    return record;
  }

  // ── Quran API ──────────────────────────────────────────────────────────

  Future<void> _fetchSurahList() async {
    if (_surahList.isNotEmpty) return;
    isSurahListLoading = true;
    surahListError = null;
    notifyListeners();
    try {
      _surahList = await QuranService.getSurahList();
    } catch (e) {
      surahListError = e.toString();
    } finally {
      isSurahListLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSurahList() => _fetchSurahList();

  Future<void> loadSurahForReader(int surahNumber) async {
    isSurahLoading = true;
    surahLoadError = null;
    notifyListeners();
    try {
      currentSurah = await QuranService.getSurah(surahNumber);
    } catch (e) {
      surahLoadError = e.toString();
    } finally {
      isSurahLoading = false;
      notifyListeners();
    }
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_santriList.map((s) => s.toJson()).toList());
      await prefs.setString('santri_list', encoded);
    } catch (_) {}
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load musyrif profile (legacy single)
      // Load pesantren info (new JSON format, fall back to legacy name string)
      final rawPesantren = prefs.getString('pesantren_info');
      if (rawPesantren != null) {
        _pesantrenInfo = PesantrenInfo.fromJson(
          jsonDecode(rawPesantren) as Map<String, dynamic>,
        );
      } else {
        // Migrate from old single-string key
        final legacyName = prefs.getString('pesantren_name') ?? '';
        if (legacyName.isNotEmpty) {
          _pesantrenInfo = PesantrenInfo(nama: legacyName);
        }
      }
      // Load active modules
      final rawModules = prefs.getStringList('active_modules');
      if (rawModules != null) {
        _activeModules.clear();
        _activeModules.addAll(rawModules);
        _activeModules.add('quran'); // always active
      }
      _musyrif = prefs.getString('musyrif_name') ?? '';
      _lembaga = prefs.getString('musyrif_lembaga') ?? '';
      _jabatan = prefs.getString('musyrif_jabatan') ?? '';
      _nomorHp = prefs.getString('musyrif_nomorhp') ?? '';
      _musyrifPhoto = prefs.getString('musyrif_photo') ?? '';
      _adminPhoto = prefs.getString('admin_photo') ?? '';
      // Restore last login role
      _currentRole = UserRole.fromKey(prefs.getString('current_role'));
      _linkedSantriId = prefs.getString('linked_santri_id');
      _linkedMusyrifId = prefs.getString('linked_musyrif_id');
      // Load musyrif list
      final rawMusyrif = prefs.getString('musyrif_list');
      if (rawMusyrif != null) {
        final list = jsonDecode(rawMusyrif) as List;
        _musyrifList = list
            .map((m) => MusyrifData.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      // Load halaqah list
      final rawHalaqah = prefs.getString('halaqah_list');
      if (rawHalaqah != null) {
        final list = jsonDecode(rawHalaqah) as List;
        _halaqahList = list
            .map((h) => HalaqahData.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      // Load kelas list
      final rawKelas = prefs.getString('kelas_list');
      if (rawKelas != null) {
        final list = jsonDecode(rawKelas) as List;
        _kelasList = list
            .map((k) => KelasData.fromJson(k as Map<String, dynamic>))
            .toList();
      }
      // Load santri list
      final raw = prefs.getString('santri_list');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _santriList = list
            .map((s) => Santri.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        // First run — seed demo data
        await _seedSampleData();
      }
      notifyListeners();
    } catch (_) {
      await _seedSampleData();
      notifyListeners();
    }
  }

  /// Seeds realistic demo data so the app is immediately usable.
  Future<void> _seedSampleData() async {
    try {
      final bundle = await DemoDataService.loadDemoData();
      _musyrifList = bundle.musyrifList;
      _halaqahList = bundle.halaqahList;
      _santriList = bundle.santriList;
      await _save();
      await _saveMusyrifList();
      await _saveHalaqahList();
      await _seedUserAccounts();
      notifyListeners();
    } catch (_) {
      _musyrifList = [];
      _halaqahList = [];
      _santriList = [];
      notifyListeners();
    }
  }

  Future<void> _seedUserAccounts() async {
    // Musyrif accounts
    for (final m in _musyrifList) {
      final username = DbHelper.makeUsername(m.nip, m.nama);
      final password = DbHelper.buildDemoCredentialValue(m.nip, m.nama);
      await DbHelper.upsertUser(
        id: 'musyrif_${m.id}',
        username: username,
        password: password,
        role: 'musyrif',
        linkedId: m.id,
      );
    }
    // OrangTua accounts (santri with NIS)
    for (final s in _santriList) {
      if (s.nis != null && s.nis!.isNotEmpty) {
        final username = DbHelper.onlyDigits(s.nis);
        final password = DbHelper.onlyDigits(s.nis);
        await DbHelper.upsertUser(
          id: 'santri_${s.id}',
          username: username,
          password: password,
          role: 'orangTua',
          linkedId: s.id,
        );
      }
    }
  }
  // ── Continuation Logic ─────────────────────────────────────────────────

  /// Returns the suggested next setoran position for a santri,
  /// or null if the santri has no history or the surah list is not loaded yet.
  SetoranContinuation? getNextSetoranSuggestion(String santriId) {
    final santri = getSantriById(santriId);
    if (santri == null || santri.setoranHistory.isEmpty || _surahList.isEmpty) {
      return null;
    }
    final last = santri.setoranHistory.last;

    SurahInfo? lastSurah;
    try {
      lastSurah = _surahList.firstWhere((s) => s.number == last.surahNumber);
    } catch (_) {
      return null;
    }

    int nextSurahNumber;
    int nextAyahStart;
    SurahInfo nextSurah;

    if (last.ayahEnd >= lastSurah.numberOfAyahs) {
      // Finished the surah — move to next
      nextSurahNumber = last.surahNumber + 1;
      if (nextSurahNumber > 114) return null;
      try {
        nextSurah = _surahList.firstWhere((s) => s.number == nextSurahNumber);
      } catch (_) {
        return null;
      }
      nextAyahStart = 1;
    } else {
      // Continue in the same surah
      nextSurahNumber = last.surahNumber;
      nextSurah = lastSurah;
      nextAyahStart = last.ayahEnd + 1;
    }

    // Suggest the same range length as the last setoran
    final rangeLen = last.ayahEnd - last.ayahStart + 1;
    final nextAyahEnd = (nextAyahStart + rangeLen - 1).clamp(
      nextAyahStart,
      nextSurah.numberOfAyahs,
    );

    return SetoranContinuation(
      surah: nextSurah,
      ayahStart: nextAyahStart,
      ayahEnd: nextAyahEnd,
      type: last.type,
    );
  }
}
