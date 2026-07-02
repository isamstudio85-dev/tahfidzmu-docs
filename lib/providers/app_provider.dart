import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import '../services/firebase_service.dart';
import '../services/demo_data_service.dart';
import '../models/graduation_event.dart';
import '../models/graduation_registration.dart';
import '../models/tasmi_record.dart';
import 'package:tahfidz_app/core/utils/quran_juz_utils.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription? _santriSub;
  StreamSubscription? _musyrifSub;
  StreamSubscription? _halaqahSub;
  StreamSubscription? _kelasSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _regSub;

  List<Santri> _santriList = [];
  List<Santri> get santriList => _santriList;
  
  List<MusyrifData> _musyrifList = [];
  List<MusyrifData> get musyrifList => _musyrifList;

  MusyrifData? getMusyrifById(String? id) {
    if (id == null) return null;
    try { return _musyrifList.firstWhere((m) => m.id == id); } catch (_) { return null; }
  }

  Future<void> seedDemoDataToCloud() async {
    final bundle = await DemoDataService.loadDemoData();
    for (var m in bundle.musyrifList) {
      await _firestore.collection('musyrif').doc(m.id).set(m.toJson());
      final userKey = m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
      await _firestore.collection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': userKey});
    }
    for (var h in bundle.halaqahList) { await _firestore.collection('halaqah').doc(h.id).set(h.toJson()); }
    for (var s in bundle.santriList) {
      await _firestore.collection('santri').doc(s.id).set(s.toJson());
      if (s.nis != null) {
        final userKey = s.nis!.replaceAll(RegExp(r'\D+'), '');
        await _firestore.collection('user_mappings').doc(userKey).set({'linkedId': s.id, 'role': 'orangTua', 'defaultPassword': userKey});
      }
    }
    for (var e in bundle.graduationEvents) { await _firestore.collection('graduation_events').doc(e.id).set(e.toJson()); }
    await updatePesantrenInfo(_pesantrenInfo);
    notifyListeners();
  }

  Future<void> addMusyrif(MusyrifData m, {String? username, String? password}) async {
    String? cloudPhotoUrl;
    if (m.photoPath != null && m.photoPath!.isNotEmpty && !m.photoPath!.startsWith('http')) {
      try { cloudPhotoUrl = await _firebase.uploadPhoto(localPath: m.photoPath!, folder: 'musyrif_photos', fileName: m.id); } catch (e) { debugPrint("Musyrif Photo Upload Failed: $e"); }
    }
    final updatedM = m.copyWith(photoPath: cloudPhotoUrl ?? m.photoPath);
    await _firestore.collection('musyrif').doc(m.id).set(updatedM.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
    await _firestore.collection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateMusyrifData(String id, MusyrifData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty && !finalPhotoPath.startsWith('http')) {
      try { finalPhotoPath = await _firebase.uploadPhoto(localPath: finalPhotoPath, folder: 'musyrif_photos', fileName: id); } catch (e) { debugPrint("Musyrif Photo Upload Failed: $e"); }
    }
    final docModel = updated.copyWith(photoPath: finalPhotoPath);
    await _firestore.collection('musyrif').doc(id).set(docModel.toJson(), SetOptions(merge: true));
  }

  Future<void> removeMusyrif(String id) async => await _firestore.collection('musyrif').doc(id).delete();

  List<HalaqahData> _halaqahList = [];
  List<HalaqahData> get halaqahList => _halaqahList;
  HalaqahData? getHalaqahById(String? id) {
    if (id == null) return null;
    try { return _halaqahList.firstWhere((h) => h.id == id); } catch (_) { return null; }
  }
  List<Santri> getSantriByHalaqah(String halaqahId) => _santriList.where((s) => s.halaqahId == halaqahId).toList();
  List<Santri> getSantriByMusyrif(String musyrifId) {
    final halaqahIds = _halaqahList.where((h) => h.musyrifId == musyrifId).map((h) => h.id).toSet();
    return _santriList.where((s) => halaqahIds.contains(s.halaqahId)).toList();
  }
  Future<void> addHalaqah(HalaqahData h) async => await _firestore.collection('halaqah').doc(h.id).set(h.toJson());
  Future<void> updateHalaqah(String id, HalaqahData updated) async => await _firestore.collection('halaqah').doc(id).update(updated.toJson());
  Future<void> removeHalaqah(String id) async => await _firestore.collection('halaqah').doc(id).delete();

  List<KelasData> _kelasList = [];
  List<KelasData> get kelasList => _kelasList;
  Future<void> addKelas(KelasData k) async => await _firestore.collection('kelas').doc(k.id).set(k.toJson());
  Future<void> updateKelas(String id, KelasData updated) async => await _firestore.collection('kelas').doc(id).update(updated.toJson());
  Future<void> removeKelas(String id) async => await _firestore.collection('kelas').doc(id).delete();

  List<GraduationEvent> _graduationEvents = [];
  List<GraduationEvent> get graduationEvents => _graduationEvents;
  Future<void> addGraduationEvent(GraduationEvent event) async => await _firestore.collection('graduation_events').doc(event.id).set(event.toJson());
  Future<void> updateGraduationEvent(String id, GraduationEvent updated) async => await _firestore.collection('graduation_events').doc(id).update(updated.toJson());
  Future<void> removeGraduationEvent(String id) async => await _firestore.collection('graduation_events').doc(id).delete();

  List<GraduationRegistration> _graduationRegistrations = [];
  List<GraduationRegistration> get graduationRegistrations => _graduationRegistrations;
  Future<void> addGraduationRegistration(GraduationRegistration reg) async => await _firestore.collection('graduation_registrations').doc(reg.id).set(reg.toJson());
  Future<void> updateGraduationRegistration(String id, GraduationRegistration updated) async => await _firestore.collection('graduation_registrations').doc(id).update(updated.toJson());
  Future<void> removeGraduationRegistration(String id) async => await _firestore.collection('graduation_registrations').doc(id).delete();

  GraduationRegistration? getRegistration(String eventId, String santriId) {
    try { return _graduationRegistrations.firstWhere((r) => r.eventId == eventId && r.santriId == santriId); } catch (_) { return null; }
  }

  List<SurahInfo> _surahList = [];
  List<SurahInfo> get surahList => List.unmodifiable(_surahList);
  bool isSurahListLoading = false;
  String? surahListError;

  Santri? activeSetoranSantri;
  SetoranType activeSetoranType = SetoranType.ziyadah;
  int activeSetoranSurahNumber = 1;
  String activeSetoranSurahName = '';
  String activeSetoranSurahEnglishName = '';
  int activeSetoranAyahStart = 1;
  int activeSetoranAyahEnd = 7;
  bool isTasmiSession = false;
  List<int> activeTasmiJuz = [];
  String activeTasmiYear = '';
  final Map<String, ErrorMark> _sessionErrors = {};
  Map<String, ErrorMark> get sessionErrors => Map.unmodifiable(_sessionErrors);

  UserRole? _currentRole;
  String? _linkedSantriId;
  String? _linkedMusyrifId;
  String? _currentUserId;
  UserRole? get currentRole => _currentRole;
  String? get linkedSantriId => _linkedSantriId;
  String? get linkedMusyrifId => _linkedMusyrifId;
  String? get currentUserId => _currentUserId;
  Santri? get linkedSantri => _linkedSantriId != null ? getSantriById(_linkedSantriId!) : null;
  MusyrifData? get linkedMusyrif => getMusyrifById(_linkedMusyrifId);
  bool get isLoggedIn => _currentRole != null;
  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isMusyrif => _currentRole == UserRole.musyrif;
  bool get isOrangTua => _currentRole == UserRole.orangTua;
  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  void login(UserRole role, {String? linkedSantriId, String? linkedMusyrifId}) {
    _currentRole = role; _linkedSantriId = linkedSantriId; _linkedMusyrifId = linkedMusyrifId; notifyListeners();
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      String email = username; if (!username.contains('@')) email = '$username@tahfidzmu.com';
      final mappingDoc = await _firestore.collection('user_mappings').doc(username.replaceAll(RegExp(r'\D+'), '')).get();
      UserCredential? cred;
      try { cred = await _firebase.signIn(email, password); } catch (e) {
        if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential') && mappingDoc.exists) {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          await _firebase.setUserData(cred.user!.uid, {'role': mappingDoc.data()?['role'], 'linkedId': mappingDoc.data()?['linkedId'], 'username': username});
        } else { rethrow; }
      }
      if (cred?.user == null) return false;
      if (cred!.user!.email == 'dasamsamsudin87@gmail.com') {
         await _firebase.setUserData(cred.user!.uid, {'role': 'admin', 'username': 'admin', 'linkedId': null});
      }
      final userData = await _firebase.getUserData(cred.user!.uid);
      if (userData == null) return false;
      _currentUserId = cred.user!.uid; _currentRole = _roleFromString(userData['role'] as String);
      _linkedSantriId = userData['linkedId'] as String?; _linkedMusyrifId = userData['linkedId'] as String?;
      if (_currentRole == UserRole.admin) { _adminPhoto = userData['photoPath'] ?? ''; }
      _setupFirestoreListeners(); notifyListeners(); return true;
    } catch (e) { return false; }
  }

  static UserRole? _roleFromString(String role) {
    switch (role) { case 'admin': return UserRole.admin; case 'musyrif': return UserRole.musyrif; case 'orangTua': return UserRole.orangTua; default: return null; }
  }

  Future<bool> changeOwnPassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser; if (user == null || user.email == null) return false;
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential); await user.updatePassword(newPassword); return true;
    } catch (e) { return false; }
  }

  Future<void> resetPasswordForLinkedId(String linkedId, String newPassword) async { debugPrint("Reset password remote requested"); }

  Future<void> logout() async {
    await _firebase.signOut(); _currentRole = null; _currentUserId = null; _linkedSantriId = null; _linkedMusyrifId = null;
    _santriSub?.cancel(); _musyrifSub?.cancel(); _halaqahSub?.cancel(); _kelasSub?.cancel(); _eventSub?.cancel(); _regSub?.cancel();
    notifyListeners();
  }

  SurahDetail? currentSurah; bool isSurahLoading = false; String? surahLoadError;
  PesantrenInfo _pesantrenInfo = const PesantrenInfo(nama: 'Al-Furqon MBS Cibiuk', alamat: 'Jl. Pulobaru Desa Cibiuk Kaler Kec Cibiuk Garut', noTelp: '081289607738', email: 'info.alfurqonmbscibiuk@gmail.com');
  PesantrenInfo get pesantrenInfo => _pesantrenInfo; String get pesantrenName => _pesantrenInfo.nama;
  Future<void> updatePesantrenInfo(PesantrenInfo info) async { _pesantrenInfo = info; await _firestore.collection('settings').doc('pesantren_info').set(info.toJson()); notifyListeners(); }

  final Set<String> _activeModules = {'quran', 'hadits', 'tajwid', 'tahsin'};
  Set<String> get activeModules => Set.unmodifiable(_activeModules);
  bool isModuleActive(String key) => _activeModules.contains(key);
  void toggleModule(String key) { if (key == 'quran') return; if (_activeModules.contains(key)) { _activeModules.remove(key); } else { _activeModules.add(key); } notifyListeners(); }

  String _adminPhoto = '';
  String get musyrif => linkedMusyrif?.nama ?? 'Musyrif';
  String get lembaga => linkedMusyrif?.lembaga ?? 'Halaqah Tahfidz';
  String get jabatan => linkedMusyrif?.jabatan ?? 'Musyrif Al-Quran';
  String get nomorHp => linkedMusyrif?.nomorHp ?? '';
  String get musyrifPhoto => linkedMusyrif?.photoPath ?? '';
  String get adminPhoto => _adminPhoto;

  Future<void> updateAdminPhoto(String path) async {
    if (_currentUserId == null) return;
    final cloudUrl = await _firebase.uploadPhoto(localPath: path, folder: 'admin_photos', fileName: _currentUserId!);
    _adminPhoto = cloudUrl; await _firebase.setUserData(_currentUserId!, {'photoPath': cloudUrl}); notifyListeners();
  }

  Future<void> updateMusyrifInfo(String name, String lembaga, {String jabatan = '', String nomorHp = ''}) async {
    if (_linkedMusyrifId == null) return;
    final m = linkedMusyrif?.copyWith(nama: name, lembaga: lembaga, jabatan: jabatan, nomorHp: nomorHp);
    if (m != null) await updateMusyrifData(_linkedMusyrifId!, m);
  }

  Future<void> updateMusyrifPhoto(String path) async {
    if (_linkedMusyrifId == null) return;
    final cloudUrl = await _firebase.uploadPhoto(localPath: path, folder: 'musyrif_photos', fileName: _linkedMusyrifId!);
    await _firestore.collection('musyrif').doc(_linkedMusyrifId!).update({'photoPath': cloudUrl});
  }

  Future<void> updateSantriPhoto(String santriId, String path) async {
    final cloudUrl = await _firebase.uploadPhoto(localPath: path, folder: 'santri_photos', fileName: santriId);
    await _firestore.collection('santri').doc(santriId).update({'photoPath': cloudUrl});
  }

  void resetAllData() async {
    final collections = ['santri', 'musyrif', 'halaqah', 'kelas', 'graduation_events', 'graduation_registrations', 'users', 'user_mappings'];
    for (var col in collections) {
      final snapshot = await _firestore.collection(col).get();
      for (var doc in snapshot.docs) { await doc.reference.delete(); }
    }
  }

  AppProvider() { initialize(); }
  Future<void> initialize() async {
    if (_isInitializing) return; _isInitializing = true; notifyListeners();
    try {
      await _fetchSurahList(); final user = _firebase.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        if (user.email == 'dasamsamsudin87@gmail.com') { await _firebase.setUserData(user.uid, {'role': 'admin', 'username': 'admin', 'linkedId': null}); }
        final userData = await _firebase.getUserData(user.uid);
        if (userData != null) {
          _currentRole = _roleFromString(userData['role'] as String); _linkedSantriId = userData['linkedId'] as String?; _linkedMusyrifId = userData['linkedId'] as String?;
          if (_currentRole == UserRole.admin) { _adminPhoto = userData['photoPath'] ?? ''; }
          _setupFirestoreListeners();
        } else { await _firebase.signOut(); }
      }
    } finally { _isInitializing = false; notifyListeners(); }
  }

  void _setupFirestoreListeners() {
    _santriSub?.cancel(); _santriSub = _firestore.collection('santri').snapshots().listen((snap) { _santriList = snap.docs.map((doc) => Santri.fromJson(doc.data())).toList(); notifyListeners(); });
    _musyrifSub?.cancel(); _musyrifSub = _firestore.collection('musyrif').snapshots().listen((snap) { _musyrifList = snap.docs.map((doc) => MusyrifData.fromJson(doc.data())).toList(); notifyListeners(); });
    _halaqahSub?.cancel(); _halaqahSub = _firestore.collection('halaqah').snapshots().listen((snap) { _halaqahList = snap.docs.map((doc) => HalaqahData.fromJson(doc.data())).toList(); notifyListeners(); });
    _kelasSub?.cancel(); _kelasSub = _firestore.collection('kelas').snapshots().listen((snap) { _kelasList = snap.docs.map((doc) => KelasData.fromJson(doc.data())).toList(); notifyListeners(); });
    _eventSub?.cancel(); _eventSub = _firestore.collection('graduation_events').snapshots().listen((snap) { _graduationEvents = snap.docs.map((doc) => GraduationEvent.fromJson(doc.data())).toList(); notifyListeners(); });
    _regSub?.cancel(); _regSub = _firestore.collection('graduation_registrations').snapshots().listen((snap) { _graduationRegistrations = snap.docs.map((doc) => GraduationRegistration.fromJson(doc.data())).toList(); notifyListeners(); });
    _firestore.collection('settings').doc('pesantren_info').get().then((doc) { if (doc.exists) { _pesantrenInfo = PesantrenInfo.fromJson(doc.data()!); notifyListeners(); } });
  }

  Future<void> addSantri(String name, {String? halaqahId, String? kelas, String? nis, String? email, String? jenisKelamin, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, List<int>? initialMemorizedJuz, String? username, String? password}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    String? cloudPhotoUrl;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { cloudPhotoUrl = await _firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: id); } catch (e) { debugPrint("Photo Upload Failed: $e"); }
    }
    final santri = Santri(id: id, name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: cloudPhotoUrl ?? photoPath, initialMemorizedJuz: initialMemorizedJuz ?? []);
    await _firestore.collection('santri').doc(id).set(santri.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : nis?.replaceAll(RegExp(r'\D+'), '') ?? id;
    await _firestore.collection('user_mappings').doc(userKey).set({'linkedId': id, 'role': 'orangTua', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateSantriInfo(String santriId, {String? name, String? nis, String? email, String? jenisKelamin, String? halaqahId, String? kelas, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, String? status, List<int>? initialMemorizedJuz}) async {
    final doc = _firestore.collection('santri').doc(santriId);
    final existing = await doc.get(); if (!existing.exists) return;
    final s = Santri.fromJson(existing.data()!);
    String? finalPhotoPath = photoPath;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { finalPhotoPath = await _firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: santriId); } catch (e) { debugPrint("Photo Upload Failed: $e"); }
    }
    final updated = s.copyWith(name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: finalPhotoPath, status: status, initialMemorizedJuz: initialMemorizedJuz);
    await doc.update(updated.toJson());
  }

  Future<void> removeSantri(String santriId) async => await _firestore.collection('santri').doc(santriId).delete();
  Santri? getSantriById(String id) { try { return _santriList.firstWhere((s) => s.id == id); } catch (_) { return null; } }
  void startSetoranSession({required Santri santri, required SetoranType type, required SurahInfo surah, required int ayahStart, required int ayahEnd}) {
    activeSetoranSantri = santri; activeSetoranType = type; activeSetoranSurahNumber = surah.number; activeSetoranSurahName = surah.name; activeSetoranSurahEnglishName = surah.englishName; activeSetoranAyahStart = ayahStart; activeSetoranAyahEnd = ayahEnd; isTasmiSession = false; _sessionErrors.clear(); notifyListeners();
  }
  void startTasmiSession({required Santri santri, required List<int> juzNumbers, required String year}) {
    activeSetoranSantri = santri; activeSetoranType = SetoranType.ziyadah; isTasmiSession = true; activeTasmiJuz = juzNumbers; activeTasmiYear = year;
    final firstJuz = juzNumbers.isEmpty ? 1 : juzNumbers.reduce((a, b) => a < b ? a : b);
    final juzRange = QuranJuzUtils.getJuzRange(firstJuz);
    activeSetoranSurahNumber = juzRange.startSurah; activeSetoranAyahStart = juzRange.startAyah; activeSetoranAyahEnd = juzRange.startAyah + 20; 
    final surah = _surahList.firstWhere((s) => s.number == activeSetoranSurahNumber, orElse: () => _surahList.first);
    activeSetoranSurahName = surah.name; activeSetoranSurahEnglishName = surah.englishName; _sessionErrors.clear(); notifyListeners();
  }
  void toggleError({required int surahNumber, required int ayahNumber, required int wordIndex, required String word, required ErrorType errorType}) {
    final key = ErrorMark.generateKey(surahNumber, ayahNumber, wordIndex);
    if (_sessionErrors.containsKey(key) && _sessionErrors[key]!.errorType == errorType) { _sessionErrors.remove(key); } else { _sessionErrors[key] = ErrorMark(wordKey: key, errorType: errorType, surahNumber: surahNumber, ayahNumber: ayahNumber, wordIndex: wordIndex, word: word); }
    notifyListeners();
  }
  void removeError(String wordKey) { _sessionErrors.remove(wordKey); notifyListeners(); }
  void clearErrors() { _sessionErrors.clear(); notifyListeners(); }
  int get sessionTajwidCount => _sessionErrors.values.where((e) => e.errorType == ErrorType.tajwid).length;
  int get sessionMakhrojCount => _sessionErrors.values.where((e) => e.errorType == ErrorType.makhroj).length;
  Future<SetoranRecord?> completeSetoran(int fluencyRating) async {
    if (activeSetoranSantri == null) return null;
    final errors = _sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(errorMarks: errors, fluencyRating: fluencyRating);
    final record = SetoranRecord(id: DateTime.now().millisecondsSinceEpoch.toString(), santriId: activeSetoranSantri!.id, type: activeSetoranType, surahNumber: activeSetoranSurahNumber, surahName: activeSetoranSurahName, surahEnglishName: activeSetoranSurahEnglishName, ayahStart: activeSetoranAyahStart, ayahEnd: activeSetoranAyahEnd, errorMarks: errors, fluencyRating: fluencyRating, date: DateTime.now(), finalScore: score);
    await _firestore.collection('santri').doc(activeSetoranSantri!.id).update({'setoranHistory': FieldValue.arrayUnion([record.toJson()])});
    _sessionErrors.clear(); notifyListeners(); return record;
  }
  Future<TasmiRecord?> completeTasmi({required List<int> juzNumbers, required int fluencyRating, required String year, String status = 'lulus', String? note}) async {
    if (activeSetoranSantri == null) return null;
    final errors = _sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(errorMarks: errors, fluencyRating: fluencyRating);
    final record = TasmiRecord(id: DateTime.now().millisecondsSinceEpoch.toString(), santriId: activeSetoranSantri!.id, juzNumbers: juzNumbers, finalScore: score, fluencyRating: fluencyRating, errorMarks: errors, date: DateTime.now(), status: status, year: year, note: note);
    await _firestore.collection('santri').doc(activeSetoranSantri!.id).update({'tasmiHistory': FieldValue.arrayUnion([record.toJson()])});
    _sessionErrors.clear(); notifyListeners(); return record;
  }
  Future<void> updateTasmiStatus(String santriId, String recordId, String newStatus) async {
    final santriDoc = _firestore.collection('santri').doc(santriId);
    final snap = await santriDoc.get(); if (!snap.exists) return;
    final s = Santri.fromJson(snap.data()!);
    final List<TasmiRecord> history = s.tasmiHistory.map((t) { if (t.id == recordId) return t.copyWith(status: newStatus); return t; }).toList();
    await santriDoc.update({'tasmiHistory': history.map((t) => t.toJson()).toList()});
  }
  Future<void> _fetchSurahList() async { if (_surahList.isNotEmpty) return; isSurahListLoading = true; notifyListeners(); try { _surahList = await QuranService.getSurahList(); } catch (e) { surahListError = e.toString(); } finally { isSurahListLoading = false; notifyListeners(); } }
  Future<void> refreshSurahList() => _fetchSurahList();
  Future<void> loadSurahForReader(int surahNumber) async {
    activeSetoranSurahNumber = surahNumber;
    final surah = _surahList.firstWhere((s) => s.number == surahNumber, orElse: () => _surahList.first);
    activeSetoranSurahName = surah.name; activeSetoranSurahEnglishName = surah.englishName; isSurahLoading = true; notifyListeners();
    try { currentSurah = await QuranService.getSurah(surahNumber); } catch (e) { surahLoadError = e.toString(); } finally { isSurahLoading = false; notifyListeners(); }
  }
  SetoranContinuation? getNextSetoranSuggestion(String santriId) {
    final santri = getSantriById(santriId); if (santri == null || santri.setoranHistory.isEmpty || _surahList.isEmpty) return null;
    final last = santri.setoranHistory.last; SurahInfo? lastSurah; try { lastSurah = _surahList.firstWhere((s) => s.number == last.surahNumber); } catch (_) { return null; }
    int nextSurahNumber; int nextAyahStart; SurahInfo nextSurah;
    if (last.ayahEnd >= lastSurah.numberOfAyahs) {
      nextSurahNumber = last.surahNumber + 1; if (nextSurahNumber > 114) return null;
      try { nextSurah = _surahList.firstWhere((s) => s.number == nextSurahNumber); } catch (_) { return null; }
      nextAyahStart = 1;
    } else { nextSurahNumber = last.surahNumber; nextSurah = lastSurah; nextAyahStart = last.ayahEnd + 1; }
    final rangeLen = last.ayahEnd - last.ayahStart + 1;
    final nextAyahEnd = (nextAyahStart + rangeLen - 1).clamp(nextAyahStart, nextSurah.numberOfAyahs);
    return SetoranContinuation(surah: nextSurah, ayahStart: nextAyahStart, ayahEnd: nextAyahEnd, type: last.type);
  }
}
