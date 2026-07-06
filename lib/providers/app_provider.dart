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

  String generateId(String collectionName) {
    return getCollection(collectionName).doc().id;
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
          await firebase.setUserData(user.uid, {
            'role': 'superAdmin',
            'username': 'superadmin',
            'linkedId': null,
            'pesantrenId': null,
          });
        }
        if (user.email == 'admin@tahfidzmu.com') {
          await firebase.setUserData(user.uid, {
            'role': 'admin',
            'username': 'admin',
            'pesantrenId': 'demo',
          });
        }
        
        final demoPesantrenDoc = await firestore.collection('pesantren').doc('demo').get();
        if (!demoPesantrenDoc.exists) {
          await firestore.collection('pesantren').doc('demo').set({
            'id': 'demo',
            'nama': 'Pesantren Demo TahfidzMU',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
          await firestore.collection('pesantren').doc('demo').collection('settings').doc('pesantren_info').set({
            'nama': 'Pesantren Demo TahfidzMU',
            'alamat': 'Jl. Pulobaru Desa Cibiuk Kaler Kec Cibiuk Garut',
            'noTelp': '081289607738',
            'email': 'admin@tahfidzmu.com',
          });
          await firestore.collection('pesantren').doc('demo').collection('user_mappings').doc('admin').set({
            'linkedId': null,
            'role': 'admin',
            'defaultPassword': 'demo123',
          });
        }
        await _migrateGlobalDataToDemo();
        final pesantrenList = await firestore.collection('pesantren').get();
        for (var doc in pesantrenList.docs) {
          await seedDemoDataForTenant(doc.id);
        }
        final userData = await firebase.getUserData(user.uid);
        if (userData != null) {
          setLoginInfo(
            roleFromString(userData['role'] as String) ?? UserRole.orangTua,
            linkedSantriId: userData['linkedId'] as String?,
            linkedMusyrifId: userData['linkedId'] as String?,
            userId: user.uid,
            pesantrenId: userData['pesantrenId'] as String?,
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

  Future<bool> loginWithCredentials(String? targetPesantrenId, String username, String password) async {
    loginError = null;
    try {
      String email = username;
      if (!username.contains('@')) email = '$username@tahfidzmu.com';
      
      final isSuperAdminEmail = email == 'dasamsamsudin87@gmail.com';
      DocumentSnapshot<Map<String, dynamic>>? mappingDoc;

      if (!isSuperAdminEmail) {
        final mappingCollection = targetPesantrenId != null 
            ? firestore.collection('pesantren').doc(targetPesantrenId).collection('user_mappings')
            : firestore.collection('user_mappings');

        mappingDoc = await mappingCollection.doc(username).get();
        if (!mappingDoc.exists) {
          final digitsOnly = username.replaceAll(RegExp(r'\D+'), '');
          if (digitsOnly.isNotEmpty) {
            mappingDoc = await mappingCollection.doc(digitsOnly).get();
          }
        }
      }
      
      UserCredential? cred;
      try {
        cred = await firebase.signIn(email, password);
      } catch (e) {
        if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential') && mappingDoc != null && mappingDoc.exists) {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          await firebase.setUserData(cred.user!.uid, {
            'role': mappingDoc.data()?['role'],
            'linkedId': mappingDoc.data()?['linkedId'],
            'username': username,
            'pesantrenId': targetPesantrenId,
          });
        } else {
          loginError = 'Username atau sandi salah.';
          rethrow;
        }
      }
      
      if (cred?.user == null) return false;
      if (cred!.user!.email == 'dasamsamsudin87@gmail.com') {
        await firebase.setUserData(cred.user!.uid, {
          'role': 'superAdmin',
          'username': 'superadmin',
          'linkedId': null,
          'pesantrenId': null,
        });
      }
      
      final userData = await firebase.getUserData(cred.user!.uid);
      if (userData == null) {
        loginError = 'Data pengguna tidak ditemukan.';
        return false;
      }

      // Check subscription status
      if (userData['pesantrenId'] != null) {
        final pDoc = await firestore.collection('pesantren').doc(userData['pesantrenId'] as String).get();
        if (pDoc.exists) {
          final pData = pDoc.data()!;
          final status = pData['status'] ?? 'active';
          final activeUntil = pData['activeUntil'] as Timestamp?;
          
          if (status == 'suspended') {
            loginError = 'Akun pesantren ditangguhkan oleh Super Admin.';
            await firebase.signOut();
            return false;
          }
          if (activeUntil != null && activeUntil.toDate().isBefore(DateTime.now())) {
            loginError = 'Masa aktif langganan pesantren Anda telah habis.';
            await firebase.signOut();
            return false;
          }
        }
      }
      
      setLoginInfo(
        roleFromString(userData['role'] as String) ?? UserRole.orangTua,
        linkedSantriId: userData['linkedId'] as String?,
        linkedMusyrifId: userData['linkedId'] as String?,
        userId: cred.user!.uid,
        pesantrenId: userData['pesantrenId'] as String?,
      );
      
      if (isAdmin) {
        _adminPhoto = userData['photoPath'] ?? '';
      }
      setupFirestoreListeners();
      return true;
    } catch (e, stack) {
      debugPrint("LOGIN_ERROR: $e");
      debugPrint("LOGIN_STACK: $stack");
      loginError ??= 'Gagal masuk. Periksa jaringan Anda.';
      return false;
    }
  }

  Future<void> logout() async {
    await performLogout();
    cancelSubscriptions();
  }

  Future<void> updatePesantrenInfo(PesantrenInfo info) async {
    pesantrenInfo = info;
    await getCollection('settings').doc('pesantren_info').set(info.toJson());
    notifyListeners();
  }

  // Management functions
  Future<void> addMusyrif(MusyrifData m, {String? username, String? password}) async {
    String? cloudPhotoUrl;
    if (m.photoPath != null && m.photoPath!.isNotEmpty && !m.photoPath!.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: m.photoPath!, folder: 'musyrif_photos', fileName: m.id); } catch (_) {}
    }
    final updatedM = m.copyWith(photoPath: cloudPhotoUrl ?? m.photoPath);
    await getCollection('musyrif').doc(m.id).set(updatedM.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
    await getCollection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateMusyrifData(String id, MusyrifData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty && !finalPhotoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: finalPhotoPath, folder: 'musyrif_photos', fileName: id); } catch (_) {}
    }
    await getCollection('musyrif').doc(id).set(updated.copyWith(photoPath: finalPhotoPath).toJson(), SetOptions(merge: true));
  }

  Future<void> removeMusyrif(String id) async => await getCollection('musyrif').doc(id).delete();
  Future<void> addHalaqah(HalaqahData h) async => await getCollection('halaqah').doc(h.id).set(h.toJson());
  Future<void> updateHalaqah(String id, HalaqahData updated) async => await getCollection('halaqah').doc(id).update(updated.toJson());
  Future<void> removeHalaqah(String id) async => await getCollection('halaqah').doc(id).delete();
  Future<void> addKelas(KelasData k) async => await getCollection('kelas').doc(k.id).set(k.toJson());
  Future<void> updateKelas(String id, KelasData updated) async => await getCollection('kelas').doc(id).update(updated.toJson());
  Future<void> removeKelas(String id) async => await getCollection('kelas').doc(id).delete();
  Future<void> addGraduationEvent(GraduationEvent event) async => await getCollection('graduation_events').doc(event.id).set(event.toJson());
  Future<void> updateGraduationEvent(String id, GraduationEvent updated) async => await getCollection('graduation_events').doc(id).update(updated.toJson());
  Future<void> removeGraduationEvent(String id) async => await getCollection('graduation_events').doc(id).delete();
  Future<void> addGraduationRegistration(GraduationRegistration reg) async => await getCollection('graduation_registrations').doc(reg.id).set(reg.toJson());
  Future<void> updateGraduationRegistration(String id, GraduationRegistration updated) async => await getCollection('graduation_registrations').doc(id).update(updated.toJson());
  Future<void> removeGraduationRegistration(String id) async => await getCollection('graduation_registrations').doc(id).delete();

  Future<void> addSantri(String name, {String? halaqahId, String? kelas, String? nis, String? email, String? jenisKelamin, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, List<int>? initialMemorizedJuz, String? username, String? password}) async {
    final id = generateId('santri');
    String? cloudPhotoUrl;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: id); } catch (_) {}
    }
    final santri = Santri(id: id, name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: cloudPhotoUrl ?? photoPath, initialMemorizedJuz: initialMemorizedJuz ?? []);
    await getCollection('santri').doc(id).set(santri.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : nis?.replaceAll(RegExp(r'\D+'), '') ?? id;
    await getCollection('user_mappings').doc(userKey).set({'linkedId': id, 'role': 'orangTua', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateSantriInfo(String santriId, {String? name, String? nis, String? email, String? jenisKelamin, String? halaqahId, String? kelas, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, String? status, List<int>? initialMemorizedJuz}) async {
    final doc = getCollection('santri').doc(santriId);
    final existing = await doc.get(); if (!existing.exists) return;
    final s = Santri.fromJson(existing.data()!);
    String? finalPhotoPath = photoPath;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: santriId); } catch (_) {}
    }
    await doc.update(s.copyWith(name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: finalPhotoPath, status: status, initialMemorizedJuz: initialMemorizedJuz).toJson());
  }

  Future<void> removeSantri(String santriId) async => await getCollection('santri').doc(santriId).delete();

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
      id: getCollection('santri').doc().id, 
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

    final String sId = activeSetoranSantri!.id;
    
    // 1. Fetch current setoran history from Firestore subcollection to calculate new aggregates
    final historySnap = await getCollection('santri').doc(sId).collection('setoranHistory').get();
    final existingRecords = historySnap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();
    
    // Calculate new aggregates using the temp Santri model
    final tempSantri = activeSetoranSantri!.copyWith(
      setoranHistory: [...existingRecords, record],
    );

    // Write setoran record to subcollection
    final setoranJson = record.toJson();
    if (pesantrenId != null) {
      setoranJson['pesantrenId'] = pesantrenId;
    }
    await getCollection('santri').doc(sId).collection('setoranHistory').doc(record.id).set(setoranJson);
    
    // Update parent santri document with new aggregates
    await getCollection('santri').doc(sId).update({
      'averageScore': tempSantri.averageScore,
      'totalSetoranCount': tempSantri.totalSetoranCount,
      'totalErrors': tempSantri.totalErrors,
      'totalZiyadahAyahs': tempSantri.totalZiyadahAyahs,
      'totalMurojaahAyahs': tempSantri.totalMurojaahAyahs,
      'totalFailedAyahs': tempSantri.totalFailedAyahs,
      'estimatedJuz': tempSantri.estimatedJuz,
      'juzCoveredByZiyadah': tempSantri.juzCoveredByZiyadah,
    });
    
    clearErrors();
    return record;
  }

  Future<TasmiRecord?> completeTasmi({required List<int> juzNumbers, required int fluencyRating, required String year, String status = 'lulus', String? note}) async {
    if (activeSetoranSantri == null) return null;
    final errors = sessionErrors.values.toList();
    final score = ScoringUtils.calculateScore(errorMarks: errors, fluencyRating: fluencyRating);
    final record = TasmiRecord(id: getCollection('santri').doc().id, santriId: activeSetoranSantri!.id, juzNumbers: juzNumbers, finalScore: score, fluencyRating: fluencyRating, errorMarks: errors, date: DateTime.now(), status: status, year: year, note: note);
    
    final String sId = activeSetoranSantri!.id;

    // Write tasmi record to subcollection
    final tasmiJson = record.toJson();
    if (pesantrenId != null) {
      tasmiJson['pesantrenId'] = pesantrenId;
    }
    await getCollection('santri').doc(sId).collection('tasmiHistory').doc(record.id).set(tasmiJson);
    
    clearErrors();
    return record;
  }

  Future<void> updateTasmiStatus(String santriId, String recordId, String newStatus) async {
    await getCollection('santri').doc(santriId).collection('tasmiHistory').doc(recordId).update({'status': newStatus});
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
      await getCollection('musyrif').doc(m.id).set(m.toJson());
      final userKey = m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
      await getCollection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': userKey});
    }
    for (var h in bundle.halaqahList) { await getCollection('halaqah').doc(h.id).set(h.toJson()); }
    for (var s in bundle.santriList) {
      await getCollection('santri').doc(s.id).set(s.toJson());
      // Seed subcollections
      for (var record in s.setoranHistory) {
        final setoranJson = record.toJson();
        if (pesantrenId != null) {
          setoranJson['pesantrenId'] = pesantrenId;
        }
        await getCollection('santri').doc(s.id).collection('setoranHistory').doc(record.id).set(setoranJson);
      }
      for (var record in s.tasmiHistory) {
        final tasmiJson = record.toJson();
        if (pesantrenId != null) {
          tasmiJson['pesantrenId'] = pesantrenId;
        }
        await getCollection('santri').doc(s.id).collection('tasmiHistory').doc(record.id).set(tasmiJson);
      }
      if (s.nis != null) {
        final userKey = s.nis!.replaceAll(RegExp(r'\D+'), '');
        await getCollection('user_mappings').doc(userKey).set({'linkedId': s.id, 'role': 'orangTua', 'defaultPassword': userKey});
      }
    }
    for (var e in bundle.graduationEvents) { await getCollection('graduation_events').doc(e.id).set(e.toJson()); }
    await updatePesantrenInfo(pesantrenInfo);
    notifyListeners();
  }

  Future<void> registerNewPesantren(String nama, String kode, String adminEmail, String adminPassword, {String? logoPath}) async {
    final pesantrenRef = firestore.collection('pesantren').doc(kode);
    
    String? logoUrl;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        logoUrl = await firebase.uploadPhoto(
          localPath: logoPath,
          folder: 'pesantren_logos',
          fileName: kode,
        );
      } catch (_) {}
    }
    
    // 1. Initialize pesantren document
    await pesantrenRef.set({
      'id': kode,
      'nama': nama,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'logoUrl': logoUrl,
      'subscriptionTier': 'Trial',
      'activeUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    
    // 2. Set default pesantren info settings
    final info = PesantrenInfo(
      nama: nama,
      alamat: 'Alamat belum diatur',
      noTelp: '-',
      email: adminEmail,
    );
    await pesantrenRef.collection('settings').doc('pesantren_info').set(info.toJson());
    
    // 3. Register Admin user account in Firebase Auth
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
    
    // 4. Set the user's role and pesantren link in global users collection
    await firebase.setUserData(cred.user!.uid, {
      'role': 'admin',
      'username': 'admin',
      'linkedId': null,
      'pesantrenId': kode,
    });

    // 5. Create user mapping inside the pesantren collection so they can login by username
    await pesantrenRef.collection('user_mappings').doc('admin').set({
      'linkedId': null,
      'role': 'admin',
      'defaultPassword': adminPassword,
    });
  }

  Future<void> updatePesantren(String id, {required String nama, String? logoPath}) async {
    final pesantrenRef = firestore.collection('pesantren').doc(id);
    
    String? logoUrl;
    if (logoPath != null && logoPath.isNotEmpty) {
      if (!logoPath.startsWith('http')) {
        try {
          logoUrl = await firebase.uploadPhoto(
            localPath: logoPath,
            folder: 'pesantren_logos',
            fileName: id,
          );
        } catch (_) {}
      } else {
        logoUrl = logoPath;
      }
    }

    final data = <String, dynamic>{
      'nama': nama,
    };
    if (logoUrl != null) {
      data['logoUrl'] = logoUrl;
    }
    await pesantrenRef.update(data);
    
    // Also update pesantren name in its info settings
    try {
      await pesantrenRef.collection('settings').doc('pesantren_info').update({
        'nama': nama,
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateSubscription(String id, {required String tier, required DateTime activeUntil, required String status}) async {
    await firestore.collection('pesantren').doc(id).update({
      'subscriptionTier': tier,
      'activeUntil': Timestamp.fromDate(activeUntil),
      'status': status,
    });
    notifyListeners();
  }

  Future<void> deletePesantren(String id) async {
    final pesantrenRef = firestore.collection('pesantren').doc(id);
    
    // 1. Delete settings/pesantren_info
    try {
      await pesantrenRef.collection('settings').doc('pesantren_info').delete();
    } catch (_) {}
    
    // 2. Delete user mappings
    try {
      final mappings = await pesantrenRef.collection('user_mappings').get();
      for (var doc in mappings.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
    
    // 3. Delete pesantren doc itself
    await pesantrenRef.delete();
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
    await getCollection('musyrif').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
  }

  Future<void> updateSantriPhoto(String santriId, String path) async {
    final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'santri_photos', fileName: santriId);
    await getCollection('santri').doc(santriId).update({'photoPath': cloudUrl});
  }

  // TODO: Implement yearly target from Firestore
  dynamic getYearlyTarget(String santriId) => null;

  void resetAllData() async {
    final collections = ['santri', 'musyrif', 'halaqah', 'kelas', 'graduation_events', 'graduation_registrations', 'user_mappings'];
    for (var col in collections) {
      final snapshot = await getCollection(col).get();
      for (var doc in snapshot.docs) { await doc.reference.delete(); }
    }
  }

  void login(UserRole role, {String? linkedSantriId, String? linkedMusyrifId, String? pesantrenId}) {
    setLoginInfo(role, linkedSantriId: linkedSantriId, linkedMusyrifId: linkedMusyrifId, pesantrenId: pesantrenId);
  }

  void loginAsTenantAdmin(String tenantId, String tenantNama) {
    setLoginInfo(
      UserRole.admin,
      linkedSantriId: null,
      linkedMusyrifId: null,
      userId: currentUserId,
      pesantrenId: tenantId,
    );
    setupFirestoreListeners();
    notifyListeners();
  }

  void switchBackToSuperAdmin() {
    setLoginInfo(
      UserRole.superAdmin,
      linkedSantriId: null,
      linkedMusyrifId: null,
      userId: currentUserId,
      pesantrenId: null,
    );
    setupFirestoreListeners();
    notifyListeners();
  }

  Future<void> _migrateGlobalDataToDemo() async {
    final demoSantri = await firestore.collection('pesantren').doc('demo').collection('santri').limit(1).get();
    if (demoSantri.docs.isNotEmpty) {
      return;
    }

    final globalSantri = await firestore.collection('santri').get();
    if (globalSantri.docs.isEmpty) {
      return;
    }

    debugPrint("Starting data migration to 'demo' pesantren...");

    Future<void> copyCollection(String collectionName) async {
      final snap = await firestore.collection(collectionName).get();
      for (var doc in snap.docs) {
        final data = doc.data();
        await firestore.collection('pesantren').doc('demo').collection(collectionName).doc(doc.id).set(data);
      }
    }

    await copyCollection('musyrif');
    await copyCollection('halaqah');
    await copyCollection('kelas');
    await copyCollection('graduation_events');
    await copyCollection('graduation_registrations');

    final infoDoc = await firestore.collection('settings').doc('pesantren_info').get();
    if (infoDoc.exists && infoDoc.data() != null) {
      await firestore.collection('pesantren').doc('demo').collection('settings').doc('pesantren_info').set(infoDoc.data()!);
    }

    for (var doc in globalSantri.docs) {
      final santriData = doc.data();
      final targetSantriRef = firestore.collection('pesantren').doc('demo').collection('santri').doc(doc.id);
      await targetSantriRef.set(santriData);

      final setoran = await doc.reference.collection('setoranHistory').get();
      for (var sDoc in setoran.docs) {
        await targetSantriRef.collection('setoranHistory').doc(sDoc.id).set(sDoc.data());
      }

      final tasmi = await doc.reference.collection('tasmiHistory').get();
      for (var tDoc in tasmi.docs) {
        await targetSantriRef.collection('tasmiHistory').doc(tDoc.id).set(tDoc.data());
      }
    }

    final mappings = await firestore.collection('user_mappings').get();
    for (var doc in mappings.docs) {
      await firestore.collection('pesantren').doc('demo').collection('user_mappings').doc(doc.id).set(doc.data());
    }

    debugPrint("Data migration to 'demo' pesantren completed successfully!");
  }

  Future<void> seedDemoDataForTenant(String tenantId) async {
    final santriCheck = await firestore.collection('pesantren').doc(tenantId).collection('santri').limit(1).get();
    if (santriCheck.docs.isNotEmpty) {
      return;
    }

    final tenantRef = firestore.collection('pesantren').doc(tenantId);

    final musyrifId = 'musyrif_ahmad';
    await tenantRef.collection('musyrif').doc(musyrifId).set({
      'id': musyrifId,
      'nama': 'Ustadz Ahmad',
      'username': 'ahmad',
      'email': 'ahmad@tahfidzmu.com',
      'status': 'active',
      'role': 'musyrif',
    });

    await tenantRef.collection('user_mappings').doc('ahmad').set({
      'linkedId': musyrifId,
      'role': 'musyrif',
      'defaultPassword': 'password123',
    });

    final kelasId = 'kelas_7a';
    await tenantRef.collection('kelas').doc(kelasId).set({
      'id': kelasId,
      'nama': 'Kelas VII A',
    });

    final halaqahId = 'halaqah_1';
    await tenantRef.collection('halaqah').doc(halaqahId).set({
      'id': halaqahId,
      'nama': 'Halaqah Abu Bakar',
      'musyrifId': musyrifId,
      'musyrifNama': 'Ustadz Ahmad',
    });

    final santri1Id = 'santri_muhammad';
    await tenantRef.collection('santri').doc(santri1Id).set({
      'id': santri1Id,
      'nama': 'Muhammad Al-Fatih',
      'nis': '1001',
      'halaqahId': halaqahId,
      'kelasId': kelasId,
      'status': 'active',
      'targetJuz': 30,
    });

    await tenantRef.collection('user_mappings').doc('1001').set({
      'linkedId': santri1Id,
      'role': 'orangTua',
      'defaultPassword': '1001',
    });

    final santri2Id = 'santri_yusuf';
    await tenantRef.collection('santri').doc(santri2Id).set({
      'id': santri2Id,
      'nama': 'Yusuf Mansur',
      'nis': '1002',
      'halaqahId': halaqahId,
      'kelasId': kelasId,
      'status': 'active',
      'targetJuz': 30,
    });

    await tenantRef.collection('user_mappings').doc('1002').set({
      'linkedId': santri2Id,
      'role': 'orangTua',
      'defaultPassword': '1002',
    });

    final setoran1Id = 'setoran_1';
    await tenantRef.collection('santri').doc(santri1Id).collection('setoranHistory').doc(setoran1Id).set({
      'id': setoran1Id,
      'santriId': santri1Id,
      'pesantrenId': tenantId,
      'date': Timestamp.now(),
      'surahId': 78,
      'surahName': 'An-Naba',
      'startVerse': 1,
      'endVerse': 10,
      'type': 'setoran',
      'status': 'lancar',
      'musyrifId': musyrifId,
    });

    final setoran2Id = 'setoran_2';
    await tenantRef.collection('santri').doc(santri1Id).collection('setoranHistory').doc(setoran2Id).set({
      'id': setoran2Id,
      'santriId': santri1Id,
      'pesantrenId': tenantId,
      'date': Timestamp.now(),
      'surahId': 78,
      'surahName': 'An-Naba',
      'startVerse': 11,
      'endVerse': 20,
      'type': 'setoran',
      'status': 'lancar',
      'musyrifId': musyrifId,
    });

    debugPrint("Seeded demo data for tenant $tenantId successfully!");
  }
}
