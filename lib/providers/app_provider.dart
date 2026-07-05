import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/surah_model.dart';
import '../models/setoran_continuation.dart';
import '../models/user_role.dart';
import '../models/musyrif_data.dart';
import '../models/halaqah_data.dart';
import '../models/kelas_data.dart';
import '../models/pesantren_info.dart';
import '../models/graduation_event.dart';
import '../models/graduation_registration.dart';
import '../models/tasmi_record.dart';
import '../services/quran_service.dart';
import '../services/demo_data_service.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';

import 'auth_mixin.dart';
import 'data_mixin.dart';
import 'session_mixin.dart';

class AppProvider extends ChangeNotifier with AuthMixin, DataMixin, SessionMixin {
  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  SurahDetail? currentSurah;
  bool isSurahLoading = false;
  String? surahLoadError;

  bool isSurahListLoading = false;
  String? surahListError;

  final Set<String> _activeModules = {'quran', 'hadits', 'tajwid', 'tahsin'};
  Set<String> get activeModules => Set.unmodifiable(_activeModules);
  bool isModuleActive(String key) => _activeModules.contains(key);
  
  void toggleModule(String key) {
    if (key == 'quran') return;
    if (_activeModules.contains(key)) {
      _activeModules.remove(key);
    } else {
      _activeModules.add(key);
    }
    notifyListeners();
  }

  String _adminPhoto = '';
  String get adminPhoto => _adminPhoto;

  Santri? get linkedSantri => linkedSantriId != null ? getSantriById(linkedSantriId!) : null;
  MusyrifData? get linkedMusyrif => getMusyrifById(linkedMusyrifId);

  String get musyrif => linkedMusyrif?.nama ?? 'Musyrif';
  String get lembaga => linkedMusyrif?.lembaga ?? 'Halaqah Tahfidz';
  String get jabatan => linkedMusyrif?.jabatan ?? 'Musyrif Al-Quran';
  String get nomorHp => linkedMusyrif?.nomorHp ?? '';
  String get musyrifPhoto => linkedMusyrif?.photoPath ?? '';

  AppProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    notifyListeners();
    try {
      await _fetchSurahList();
      final user = firebase.currentUser;
      if (user != null) {
        if (user.email == 'dasamsamsudin87@gmail.com') {
          await firebase.setUserData(user.uid, {'role': 'admin', 'username': 'admin', 'linkedId': null});
        }
        final userData = await firebase.getUserData(user.uid);
        if (userData != null) {
          setLoginInfo(
            roleFromString(userData['role'] as String) ?? UserRole.orangTua,
            linkedSantriId: userData['linkedId'] as String?,
            linkedMusyrifId: userData['linkedId'] as String?,
            userId: user.uid,
          );
          if (isAdmin) {
            _adminPhoto = userData['photoPath'] ?? '';
          }
          setupFirestoreListeners();
        } else {
          await firebase.signOut();
        }
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSurahList() async {
    if (surahList.isNotEmpty) return;
    isSurahListLoading = true;
    notifyListeners();
    try {
      final list = await QuranService.getSurahList();
      surahList = list;
    } catch (e) {
      surahListError = e.toString();
    } finally {
      isSurahListLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSurahList() => _fetchSurahList();

  Future<void> loadSurahForReader(int surahNumber) async {
    activeSetoranSurahNumber = surahNumber;
    final surahInfo = surahList.firstWhere((s) => s.number == surahNumber, orElse: () => surahList.first);
    activeSetoranSurahName = surahInfo.name;
    activeSetoranSurahEnglishName = surahInfo.englishName;
    isSurahLoading = true;
    notifyListeners();
    try {
      currentSurah = await QuranService.getSurah(surahNumber);
      
      // Speculative pre-caching for next surah to make navigation "instant"
      if (surahNumber < 114) {
        QuranService.getSurah(surahNumber + 1);
      }
    } catch (e) {
      surahLoadError = e.toString();
    } finally {
      isSurahLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      String email = username;
      if (!username.contains('@')) email = '$username@tahfidzmu.com';
      final mappingDoc = await firestore.collection('user_mappings').doc(username.replaceAll(RegExp(r'\D+'), '')).get();
      
      UserCredential? cred;
      try {
        cred = await firebase.signIn(email, password);
      } catch (e) {
        if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential') && mappingDoc.exists) {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          await firebase.setUserData(cred.user!.uid, {
            'role': mappingDoc.data()?['role'],
            'linkedId': mappingDoc.data()?['linkedId'],
            'username': username
          });
        } else {
          rethrow;
        }
      }
      
      if (cred?.user == null) return false;
      if (cred!.user!.email == 'dasamsamsudin87@gmail.com') {
        await firebase.setUserData(cred.user!.uid, {'role': 'admin', 'username': 'admin', 'linkedId': null});
      }
      
      final userData = await firebase.getUserData(cred.user!.uid);
      if (userData == null) return false;
      
      setLoginInfo(
        roleFromString(userData['role'] as String) ?? UserRole.orangTua,
        linkedSantriId: userData['linkedId'] as String?,
        linkedMusyrifId: userData['linkedId'] as String?,
        userId: cred.user!.uid,
      );
      
      if (isAdmin) {
        _adminPhoto = userData['photoPath'] ?? '';
      }
      setupFirestoreListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await performLogout();
    cancelSubscriptions();
  }

  Future<void> updatePesantrenInfo(PesantrenInfo info) async {
    pesantrenInfo = info;
    await firestore.collection('settings').doc('pesantren_info').set(info.toJson());
    notifyListeners();
  }

  // Management functions
  Future<void> addMusyrif(MusyrifData m, {String? username, String? password}) async {
    String? cloudPhotoUrl;
    if (m.photoPath != null && m.photoPath!.isNotEmpty && !m.photoPath!.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: m.photoPath!, folder: 'musyrif_photos', fileName: m.id); } catch (_) {}
    }
    final updatedM = m.copyWith(photoPath: cloudPhotoUrl ?? m.photoPath);
    await firestore.collection('musyrif').doc(m.id).set(updatedM.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
    await firestore.collection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateMusyrifData(String id, MusyrifData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty && !finalPhotoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: finalPhotoPath, folder: 'musyrif_photos', fileName: id); } catch (_) {}
    }
    await firestore.collection('musyrif').doc(id).set(updated.copyWith(photoPath: finalPhotoPath).toJson(), SetOptions(merge: true));
  }

  Future<void> removeMusyrif(String id) async => await firestore.collection('musyrif').doc(id).delete();
  Future<void> addHalaqah(HalaqahData h) async => await firestore.collection('halaqah').doc(h.id).set(h.toJson());
  Future<void> updateHalaqah(String id, HalaqahData updated) async => await firestore.collection('halaqah').doc(id).update(updated.toJson());
  Future<void> removeHalaqah(String id) async => await firestore.collection('halaqah').doc(id).delete();
  Future<void> addKelas(KelasData k) async => await firestore.collection('kelas').doc(k.id).set(k.toJson());
  Future<void> updateKelas(String id, KelasData updated) async => await firestore.collection('kelas').doc(id).update(updated.toJson());
  Future<void> removeKelas(String id) async => await firestore.collection('kelas').doc(id).delete();
  Future<void> addGraduationEvent(GraduationEvent event) async => await firestore.collection('graduation_events').doc(event.id).set(event.toJson());
  Future<void> updateGraduationEvent(String id, GraduationEvent updated) async => await firestore.collection('graduation_events').doc(id).update(updated.toJson());
  Future<void> removeGraduationEvent(String id) async => await firestore.collection('graduation_events').doc(id).delete();
  Future<void> addGraduationRegistration(GraduationRegistration reg) async => await firestore.collection('graduation_registrations').doc(reg.id).set(reg.toJson());
  Future<void> updateGraduationRegistration(String id, GraduationRegistration updated) async => await firestore.collection('graduation_registrations').doc(id).update(updated.toJson());
  Future<void> removeGraduationRegistration(String id) async => await firestore.collection('graduation_registrations').doc(id).delete();

  Future<void> addSantri(String name, {String? halaqahId, String? kelas, String? nis, String? email, String? jenisKelamin, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, List<int>? initialMemorizedJuz, String? username, String? password}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    String? cloudPhotoUrl;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: id); } catch (_) {}
    }
    final santri = Santri(id: id, name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: cloudPhotoUrl ?? photoPath, initialMemorizedJuz: initialMemorizedJuz ?? []);
    await firestore.collection('santri').doc(id).set(santri.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : nis?.replaceAll(RegExp(r'\D+'), '') ?? id;
    await firestore.collection('user_mappings').doc(userKey).set({'linkedId': id, 'role': 'orangTua', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateSantriInfo(String santriId, {String? name, String? nis, String? email, String? jenisKelamin, String? halaqahId, String? kelas, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, String? status, List<int>? initialMemorizedJuz}) async {
    final doc = firestore.collection('santri').doc(santriId);
    final existing = await doc.get(); if (!existing.exists) return;
    final s = Santri.fromJson(existing.data()!);
    String? finalPhotoPath = photoPath;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: santriId); } catch (_) {}
    }
    await doc.update(s.copyWith(name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: finalPhotoPath, status: status, initialMemorizedJuz: initialMemorizedJuz).toJson());
  }

  Future<void> removeSantri(String santriId) async => await firestore.collection('santri').doc(santriId).delete();

  Future<SetoranRecord?> completeSetoran(int fluencyRating) async {
    if (activeSetoranSantri == null) return null;
    final errors = sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(errorMarks: errors, fluencyRating: fluencyRating);
    
    final passed = sessionPassedAyahs.toList()..sort();
    final failed = sessionFailedAyahs.toList()..sort();
    
    // Logic Baru: Sesi berakhir pada ayat TERAKHIR yang ditandai LULUS
    int start = activeSetoranAyahStart;
    int end = activeSetoranAyahEnd;
    
    if (passed.isNotEmpty) {
      end = passed.last;
      start = (passed.first < activeSetoranAyahStart) ? passed.first : activeSetoranAyahStart;
    } else if (failed.isNotEmpty) {
      end = failed.last;
      start = (failed.first < activeSetoranAyahStart) ? failed.first : activeSetoranAyahStart;
    }

    final record = SetoranRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      santriId: activeSetoranSantri!.id, 
      type: activeSetoranType, 
      surahNumber: activeSetoranSurahNumber, 
      surahName: activeSetoranSurahName, 
      surahEnglishName: activeSetoranSurahEnglishName, 
      ayahStart: start, 
      ayahEnd: end, 
      passedAyahs: passed,
      failedAyahs: failed,
      errorMarks: errors, 
      fluencyRating: fluencyRating, 
      date: DateTime.now(), 
      finalScore: score
    );
    
    await firestore.collection('santri').doc(activeSetoranSantri!.id).update({
      'setoranHistory': FieldValue.arrayUnion([record.toJson()])
    });
    
    clearErrors();
    return record;
  }

  Future<TasmiRecord?> completeTasmi({required List<int> juzNumbers, required int fluencyRating, required String year, String status = 'lulus', String? note}) async {
    if (activeSetoranSantri == null) return null;
    final errors = sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(errorMarks: errors, fluencyRating: fluencyRating);
    final record = TasmiRecord(id: DateTime.now().millisecondsSinceEpoch.toString(), santriId: activeSetoranSantri!.id, juzNumbers: juzNumbers, finalScore: score, fluencyRating: fluencyRating, errorMarks: errors, date: DateTime.now(), status: status, year: year, note: note);
    await firestore.collection('santri').doc(activeSetoranSantri!.id).update({'tasmiHistory': FieldValue.arrayUnion([record.toJson()])});
    clearErrors();
    return record;
  }

  Future<void> updateTasmiStatus(String santriId, String recordId, String newStatus) async {
    final santriDoc = firestore.collection('santri').doc(santriId);
    final snap = await santriDoc.get(); if (!snap.exists) return;
    final s = Santri.fromJson(snap.data()!);
    final List<TasmiRecord> history = s.tasmiHistory.map((t) { if (t.id == recordId) return t.copyWith(status: newStatus); return t; }).toList();
    await santriDoc.update({'tasmiHistory': history.map((t) => t.toJson()).toList()});
  }

  SetoranContinuation? getNextSetoranSuggestion(String santriId) {
    final santri = getSantriById(santriId); 
    if (santri == null || surahList.isEmpty) return null;
    
    // 1. Cek Hutang (Ayat Gagal) di riwayat terakhir
    if (santri.setoranHistory.isNotEmpty) {
      final last = santri.setoranHistory.last;
      if (last.failedAyahs.isNotEmpty) {
        final firstFailed = (List<int>.from(last.failedAyahs)..sort()).first;
        final surah = surahList.firstWhere((s) => s.number == last.surahNumber, orElse: () => surahList.first);
        return SetoranContinuation(
          surah: surah,
          ayahStart: firstFailed,
          ayahEnd: firstFailed,
          type: last.type,
        );
      }

      // 2. Lanjut dari ayat terakhir yang lulus + 1
      final lastSurahInfo = surahList.firstWhere((s) => s.number == last.surahNumber, orElse: () => surahList.first);
      int nextSurahNumber = last.surahNumber;
      int nextAyahStart = last.ayahEnd + 1;

      if (nextAyahStart > lastSurahInfo.numberOfAyahs) {
        nextSurahNumber++;
        nextAyahStart = 1;
      }

      if (nextSurahNumber <= 114) {
        final nextSurahInfo = surahList.firstWhere((s) => s.number == nextSurahNumber);
        return SetoranContinuation(
          surah: nextSurahInfo,
          ayahStart: nextAyahStart,
          ayahEnd: nextAyahStart,
          type: last.type,
        );
      }
    }
    
    return SetoranContinuation(
      surah: surahList.first,
      ayahStart: 1,
      ayahEnd: 1,
      type: SetoranType.ziyadah,
    );
  }

  Future<void> seedDemoDataToCloud() async {
    final bundle = await DemoDataService.loadDemoData();
    for (var m in bundle.musyrifList) {
      await firestore.collection('musyrif').doc(m.id).set(m.toJson());
      final userKey = m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
      await firestore.collection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': userKey});
    }
    for (var h in bundle.halaqahList) { await firestore.collection('halaqah').doc(h.id).set(h.toJson()); }
    for (var s in bundle.santriList) {
      await firestore.collection('santri').doc(s.id).set(s.toJson());
      if (s.nis != null) {
        final userKey = s.nis!.replaceAll(RegExp(r'\D+'), '');
        await firestore.collection('user_mappings').doc(userKey).set({'linkedId': s.id, 'role': 'orangTua', 'defaultPassword': userKey});
      }
    }
    for (var e in bundle.graduationEvents) { await firestore.collection('graduation_events').doc(e.id).set(e.toJson()); }
    await updatePesantrenInfo(pesantrenInfo);
    notifyListeners();
  }

  Future<void> updateAdminPhoto(String path) async {
    if (currentUserId == null) return;
    final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'admin_photos', fileName: currentUserId!);
    _adminPhoto = cloudUrl; await firebase.setUserData(currentUserId!, {'photoPath': cloudUrl}); notifyListeners();
  }

  Future<bool> changeOwnPassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser; if (user == null || user.email == null) return false;
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential); await user.updatePassword(newPassword); return true;
    } catch (e) { return false; }
  }

  Future<void> resetPasswordForLinkedId(String linkedId, String newPassword) async { 
    debugPrint("Reset password remote requested for $linkedId"); 
  }

  Future<void> updateMusyrifInfo(String name, String lembaga, {String jabatan = '', String nomorHp = ''}) async {
    if (linkedMusyrifId == null) return;
    final m = linkedMusyrif?.copyWith(nama: name, lembaga: lembaga, jabatan: jabatan, nomorHp: nomorHp);
    if (m != null) await updateMusyrifData(linkedMusyrifId!, m);
  }

  Future<void> updateMusyrifPhoto(String path) async {
    if (linkedMusyrifId == null) return;
    final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'musyrif_photos', fileName: linkedMusyrifId!);
    await firestore.collection('musyrif').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
  }

  Future<void> updateSantriPhoto(String santriId, String path) async {
    final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'santri_photos', fileName: santriId);
    await firestore.collection('santri').doc(santriId).update({'photoPath': cloudUrl});
  }

  // TODO: Implement yearly target from Firestore
  dynamic getYearlyTarget(String santriId) => null;

  void resetAllData() async {
    final collections = ['santri', 'musyrif', 'halaqah', 'kelas', 'graduation_events', 'graduation_registrations', 'users', 'user_mappings'];
    for (var col in collections) {
      final snapshot = await firestore.collection(col).get();
      for (var doc in snapshot.docs) { await doc.reference.delete(); }
    }
  }

  void login(UserRole role, {String? linkedSantriId, String? linkedMusyrifId}) {
    setLoginInfo(role, linkedSantriId: linkedSantriId, linkedMusyrifId: linkedMusyrifId);
  }
}
