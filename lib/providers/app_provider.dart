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
import '../models/pengawas_data.dart';
import '../models/presensi_halaqah.dart';
import '../models/app_notification.dart';
import '../services/quran_service.dart';

import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import '../services/login_preferences_service.dart';

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

  final Set<String> _activeModules = {'quran', 'hadits', 'tajwid', 'tahsin', 'graduation'};
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
  
  PengawasData? getPengawasById(String id) {
    final list = pengawasList.where((p) => p.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }
  
  PengawasData? get linkedPengawas => linkedMusyrifId != null ? getPengawasById(linkedMusyrifId!) : null;

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
        // Auto-assign superAdmin role for the owner
        if (user.email == 'dasamsamsudin87@gmail.com') {
          await firebase.setUserData(user.uid, {
            'role': 'superAdmin',
            'username': 'superadmin',
            'linkedId': null,
            'pesantrenId': null,
          });
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
          await setupFirestoreListeners();
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
      } else if (mappingDoc != null && mappingDoc.exists) {
        await firebase.setUserData(cred.user!.uid, {
          'role': mappingDoc.data()?['role'],
          'linkedId': mappingDoc.data()?['linkedId'],
          'username': username,
          'pesantrenId': targetPesantrenId,
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
      await setupFirestoreListeners();

      // Save account credentials for the account switcher
      final displayName = isOrangTua
          ? (linkedSantri?.name ?? username)
          : (isMusyrif 
              ? (linkedMusyrif?.nama ?? username) 
              : (isPengawas ? (linkedPengawas?.nama ?? username) : 'Admin'));
      final photoPath = isOrangTua
          ? linkedSantri?.photoPath
          : (isMusyrif 
              ? linkedMusyrif?.photoPath 
              : (isPengawas ? linkedPengawas?.photoPath : null));

      try {
        await LoginPreferencesService.saveAccount(SavedAccount(
          username: username,
          password: password,
          pesantrenId: targetPesantrenId,
          displayName: displayName,
          photoPath: photoPath,
          role: userData['role'] as String,
          linkedId: userData['linkedId'] as String?,
        ));
      } catch (e) {
        debugPrint("Error saving account to switcher: $e");
      }

      return true;
    } catch (e, stack) {
      debugPrint("LOGIN_ERROR: $e");
      debugPrint("LOGIN_STACK: $stack");
      loginError ??= 'Gagal masuk. Periksa jaringan Anda.';
      return false;
    }
  }

  Future<bool> switchAccount(SavedAccount account) async {
    _isInitializing = true;
    notifyListeners();
    try {
      await firebase.signOut();
      final success = await loginWithCredentials(
        account.pesantrenId,
        account.username,
        account.password,
      );
      return success;
    } catch (e) {
      debugPrint("Error switching account: $e");
      return false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> updateSetoranRecord(String santriId, SetoranRecord record) async {
    // 1. Save record to Firestore
    final setoranJson = record.toJson();
    if (pesantrenId != null) {
      setoranJson['pesantrenId'] = pesantrenId;
    }
    await getCollection('santri').doc(santriId).collection('setoranHistory').doc(record.id).set(setoranJson);

    final now = DateTime.now();
    if (record.date.year == now.year && record.date.month == now.month && record.date.day == now.day) {
      await setSantriKehadiranStatus(santriId, 'setoran');
    }
    
    // Trigger setoran notification to parent
    await triggerSetoranNotification(santriId, record);

    // 2. Fetch all records to recalculate aggregates
    final historySnap = await getCollection('santri').doc(santriId).collection('setoranHistory').get();
    final allRecords = historySnap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();

    final targetSantri = getSantriById(santriId);
    if (targetSantri != null) {
      final tempSantri = targetSantri.copyWith(setoranHistory: allRecords);
      await getCollection('santri').doc(santriId).update({
        'averageScore': tempSantri.averageScore,
        'totalSetoranCount': tempSantri.totalSetoranCount,
        'totalErrors': tempSantri.totalErrors,
        'totalZiyadahAyahs': tempSantri.totalZiyadahAyahs,
        'totalMurojaahAyahs': tempSantri.totalMurojaahAyahs,
        'totalFailedAyahs': tempSantri.totalFailedAyahs,
        'estimatedJuz': tempSantri.estimatedJuz,
        'juzCoveredByZiyadah': tempSantri.juzCoveredByZiyadah,
      });
    }
    notifyListeners();
  }

  Future<void> deleteSetoranRecord(String santriId, String recordId) async {
    // 1. Delete record from Firestore
    await getCollection('santri').doc(santriId).collection('setoranHistory').doc(recordId).delete();

    // 2. Fetch remaining records to recalculate aggregates
    final historySnap = await getCollection('santri').doc(santriId).collection('setoranHistory').get();
    final allRecords = historySnap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();

    final targetSantri = getSantriById(santriId);
    if (targetSantri != null) {
      final tempSantri = targetSantri.copyWith(setoranHistory: allRecords);
      await getCollection('santri').doc(santriId).update({
        'averageScore': tempSantri.averageScore,
        'totalSetoranCount': tempSantri.totalSetoranCount,
        'totalErrors': tempSantri.totalErrors,
        'totalZiyadahAyahs': tempSantri.totalZiyadahAyahs,
        'totalMurojaahAyahs': tempSantri.totalMurojaahAyahs,
        'totalFailedAyahs': tempSantri.totalFailedAyahs,
        'estimatedJuz': tempSantri.estimatedJuz,
        'juzCoveredByZiyadah': tempSantri.juzCoveredByZiyadah,
      });
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await performLogout();
    cancelSubscriptions();
  }

  @override
  void startSetoranSession({
    required Santri santri,
    required SetoranType type,
    required SurahInfo surah,
    required int ayahStart,
    required int ayahEnd,
  }) {
    super.startSetoranSession(
      santri: santri,
      type: type,
      surah: surah,
      ayahStart: ayahStart,
      ayahEnd: ayahEnd,
    );
    _writeActiveSessionToFirestore(
      santriName: santri.name,
      detail: '${type.label}: ${surah.englishName} $ayahStart-$ayahEnd',
    );
  }

  @override
  void startTasmiSession({
    required Santri santri,
    required List<int> juzNumbers,
    required String year,
  }) {
    super.startTasmiSession(
      santri: santri,
      juzNumbers: juzNumbers,
      year: year,
    );
    final juzStr = juzNumbers.join(', ');
    _writeActiveSessionToFirestore(
      santriName: santri.name,
      detail: 'Tasmi\' Juz [$juzStr]',
    );
  }

  Future<void> _writeActiveSessionToFirestore({
    required String santriName,
    required String detail,
  }) async {
    final mId = linkedMusyrifId;
    if (mId == null) return;
    final mName = linkedMusyrif?.nama ?? 'Musyrif';
    try {
      final sessionJson = {
        'id': mId,
        'musyrifId': mId,
        'musyrifName': mName,
        'santriName': santriName,
        'detail': detail,
        'startedAt': FieldValue.serverTimestamp(),
      };
      if (pesantrenId != null) {
        sessionJson['pesantrenId'] = pesantrenId!;
      }
      await getCollection('active_sessions').doc(mId).set(sessionJson);
    } catch (e) {
      debugPrint("Error writing active session: $e");
    }
  }

  Future<void> endSetoranSession() async {
    if (linkedMusyrifId != null && activeSetoranSantri != null) {
      try {
        await getCollection('active_sessions').doc(linkedMusyrifId!).delete();
      } catch (e) {
        debugPrint("Error clearing active session: $e");
      }
    }
    activeSetoranSantri = null;
    clearErrors();
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
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: m.photoPath!, folder: 'musyrif_photos', fileName: m.id); } catch (e) { debugPrint('Failed to upload musyrif photo: $e'); }
    }
    final updatedM = m.copyWith(photoPath: cloudPhotoUrl ?? m.photoPath);
    await getCollection('musyrif').doc(m.id).set(updatedM.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : m.nip?.replaceAll(RegExp(r'\D+'), '') ?? m.id;
    await getCollection('user_mappings').doc(userKey).set({'linkedId': m.id, 'role': 'musyrif', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateMusyrifData(String id, MusyrifData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty && !finalPhotoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: finalPhotoPath, folder: 'musyrif_photos', fileName: id); } catch (e) { debugPrint('Failed to update musyrif photo: $e'); }
    }
    await getCollection('musyrif').doc(id).set(updated.copyWith(photoPath: finalPhotoPath).toJson(), SetOptions(merge: true));
  }

  Future<void> removeMusyrif(String id) async => await getCollection('musyrif').doc(id).delete();

  Future<void> addPengawas(PengawasData p, {required String username, required String password}) async {
    String? cloudPhotoUrl;
    if (p.photoPath != null && p.photoPath!.isNotEmpty && !p.photoPath!.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: p.photoPath!, folder: 'pengawas_photos', fileName: p.id); } catch (e) { debugPrint('Failed to upload pengawas photo: $e'); }
    }
    final updatedP = p.copyWith(photoPath: cloudPhotoUrl ?? p.photoPath);
    await getCollection('pengawas').doc(p.id).set(updatedP.toJson());
    await getCollection('user_mappings').doc(username).set({
      'linkedId': p.id,
      'role': 'pengawas',
      'defaultPassword': password,
    });
  }

  Future<void> updatePengawasData(String id, PengawasData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty && !finalPhotoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: finalPhotoPath, folder: 'pengawas_photos', fileName: id); } catch (e) { debugPrint('Failed to update pengawas photo: $e'); }
    }
    await getCollection('pengawas').doc(id).set(updated.copyWith(photoPath: finalPhotoPath).toJson(), SetOptions(merge: true));
  }

  Future<void> removePengawas(String id, String username) async {
    await getCollection('pengawas').doc(id).delete();
    await getCollection('user_mappings').doc(username).delete();
  }

  String? getTodaySantriStatus(String santriId) {
    final now = DateTime.now();
    for (final p in presensiList) {
      if (p.tanggal.year == now.year &&
          p.tanggal.month == now.month &&
          p.tanggal.day == now.day) {
        if (p.daftarHadir.containsKey(santriId)) {
          return p.daftarHadir[santriId];
        }
      }
    }
    return null;
  }

  Future<String> getLoginQrData(String userId) async {
    final snap = await getCollection('user_mappings').where('linkedId', isEqualTo: userId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final username = doc.id;
      final pwd = doc.data()['defaultPassword'] ?? username;
      return 'tahfidzmu:login:$pesantrenId:$username:$pwd';
    }
    final doc = await getCollection('user_mappings').doc(userId).get();
    final pwd = doc.data()?['defaultPassword'] ?? userId;
    return 'tahfidzmu:login:$pesantrenId:$userId:$pwd';
  }

  Future<void> sendNotification(String targetUserId, String title, String body, String type) async {
    final ref = firestore.collection('users').doc(targetUserId).collection('notifications').doc();
    final notif = AppNotification(
      id: ref.id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      targetUserId: targetUserId,
      type: type,
    );
    await ref.set(notif.toJson());
  }

  Future<void> markAllNotificationsAsRead() async {
    if (currentUserId == null) return;
    final snap = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) return;
    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> triggerSetoranNotification(String santriId, SetoranRecord record) async {
    final santri = getSantriById(santriId);
    if (santri == null) return;
    final snap = await firestore
        .collection('users')
        .where('role', isEqualTo: 'orangTua')
        .where('linkedId', isEqualTo: santriId)
        .get();

    for (var doc in snap.docs) {
      final parentUid = doc.id;
      final typeStr = record.type == SetoranType.ziyadah ? 'Ziyadah' : 'Murojaah';
      final statusStr = record.gradeName;
      final scoreVal = record.finalScore.toStringAsFixed(0);
      
      final title = "Setoran Hafalan Baru ($typeStr)";
      final body = "Alhamdulillah, ${santri.name} baru saja menyetor hafalan $typeStr: Surah ${record.surahName} (${record.ayahStart}-${record.ayahEnd}) dengan predikat $statusStr (Nilai: $scoreVal).";

      await sendNotification(parentUid, title, body, 'setoran');
    }
  }

  Future<void> setSantriKehadiranStatus(String santriId, String status) async {
    final santri = getSantriById(santriId);
    if (santri == null) return;
    final halaqahId = santri.halaqahId;
    if (halaqahId == null) return;
    final halaqah = getHalaqahById(halaqahId);
    final halaqahNama = halaqah?.nama ?? 'Halaqah';
    final musyrifId = halaqah?.musyrifId ?? '';
    final musyrif = getMusyrifById(musyrifId);
    final musyrifNama = musyrif?.nama ?? 'Musyrif';

    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final docId = "${halaqahId}_$dateStr";

    final docRef = getCollection('presensi').doc(docId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final existing = PresensiHalaqah.fromJson(docSnap.data()!);
      final updatedDaftar = Map<String, String>.from(existing.daftarHadir);
      updatedDaftar[santriId] = status;
      await docRef.update({
        'daftarHadir': updatedDaftar,
        'waktuSubmit': Timestamp.fromDate(now),
      });
    } else {
      final newPresensi = PresensiHalaqah(
        id: docId,
        halaqahId: halaqahId,
        halaqahNama: halaqahNama,
        musyrifId: musyrifId,
        musyrifNama: musyrifNama,
        tanggal: DateTime(now.year, now.month, now.day),
        waktuSubmit: now,
        daftarHadir: {santriId: status},
      );
      await docRef.set(newPresensi.toJson());
    }

    final parentSnap = await firestore
        .collection('users')
        .where('role', isEqualTo: 'orangTua')
        .where('linkedId', isEqualTo: santriId)
        .get();

    String displayStatus;
    String statusDesc;
    switch (status) {
      case 'setoran':
        displayStatus = 'Setoran (Hadir)';
        statusDesc = 'Anak Anda hadir di halaqah dan sudah melakukan setoran hafalan.';
        break;
      case 'ditunda':
        displayStatus = 'Ditunda (Bukan Sesi)';
        statusDesc = 'Anak Anda hadir di halaqah, namun ditunda giliran setorannya hari ini karena keterbatasan waktu.';
        break;
      case 'sakit':
        displayStatus = 'Sakit';
        statusDesc = 'Anak Anda tidak dapat mengikuti halaqah hari ini karena sakit.';
        break;
      case 'izin':
        displayStatus = 'Izin';
        statusDesc = 'Anak Anda tidak mengikuti halaqah hari ini karena telah meminta izin sebelumnya.';
        break;
      case 'alfa':
        displayStatus = 'Alfa (Tanpa Keterangan)';
        statusDesc = 'Anak Anda tidak mengikuti halaqah hari ini tanpa keterangan.';
        break;
      default:
        displayStatus = status.toUpperCase();
        statusDesc = 'Status kehadiran anak Anda diperbarui menjadi $displayStatus.';
    }

    for (var doc in parentSnap.docs) {
      final parentUid = doc.id;
      final title = "Laporan Kehadiran Hari Ini - $displayStatus";
      final body = "Pemberitahuan halaqah ${santri.name}: $statusDesc";
      await sendNotification(parentUid, title, body, 'presensi');
    }
  }
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

  Future<void> addSantri(String name, {String? halaqahId, String? kelas, String? nis, String? email, String? jenisKelamin, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, String? tanggalLahir, List<int>? initialMemorizedJuz, String? username, String? password}) async {
    final id = generateId('santri');
    String? cloudPhotoUrl;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { cloudPhotoUrl = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: id); } catch (e) { debugPrint('Failed to upload santri photo: $e'); }
    }
    final santri = Santri(id: id, name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: cloudPhotoUrl ?? photoPath, tanggalLahir: tanggalLahir, initialMemorizedJuz: initialMemorizedJuz ?? []);
    await getCollection('santri').doc(id).set(santri.toJson());
    final userKey = (username?.isNotEmpty ?? false) ? username! : nis?.replaceAll(RegExp(r'\D+'), '') ?? id;
    await getCollection('user_mappings').doc(userKey).set({'linkedId': id, 'role': 'orangTua', 'defaultPassword': password ?? userKey});
  }

  Future<void> updateSantriInfo(String santriId, {String? name, String? nis, String? email, String? jenisKelamin, String? halaqahId, String? kelas, String? namaOrangTua, String? namaAyah, String? namaIbu, String? nomorHpWali, String? targetHafalan, String? photoPath, String? tanggalLahir, String? status, List<int>? initialMemorizedJuz}) async {
    final doc = getCollection('santri').doc(santriId);
    final existing = await doc.get(); if (!existing.exists) return;
    final s = Santri.fromJson(existing.data()!);
    String? finalPhotoPath = photoPath;
    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try { finalPhotoPath = await firebase.uploadPhoto(localPath: photoPath, folder: 'santri_photos', fileName: santriId); } catch (e) { debugPrint('Failed to update santri photo: $e'); }
    }
    await doc.update(s.copyWith(name: name, nis: nis, email: email, jenisKelamin: jenisKelamin, kelas: kelas, halaqahId: halaqahId, namaOrangTua: namaOrangTua, namaAyah: namaAyah, namaIbu: namaIbu, nomorHpWali: nomorHpWali, targetHafalan: targetHafalan, photoPath: finalPhotoPath, tanggalLahir: tanggalLahir, status: status, initialMemorizedJuz: initialMemorizedJuz).toJson());
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
    
    final now = DateTime.now();
    if (record.date.year == now.year && record.date.month == now.month && record.date.day == now.day) {
      await setSantriKehadiranStatus(sId, 'setoran');
    }

    // Trigger setoran notification to parent
    await triggerSetoranNotification(sId, record);
    
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
    
    await setSantriKehadiranStatus(sId, 'setoran');
    await endSetoranSession();
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
    
    await endSetoranSession();
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
      } catch (e) { debugPrint('Failed to upload pesantren logo: $e'); }
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
    
    // 3. Create user mapping — akun Firebase Auth admin akan otomatis
    //    dibuat saat admin pertama kali login (auto-create di loginWithCredentials)
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
        } catch (e) { debugPrint('Failed to upload pesantren logo: $e'); }
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
    } catch (e) { debugPrint('Failed to update pesantren info name: $e'); }
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
    } catch (e) { debugPrint('Failed to delete pesantren settings: $e'); }
    
    // 2. Delete user mappings
    try {
      final mappings = await pesantrenRef.collection('user_mappings').get();
      for (var doc in mappings.docs) {
        await doc.reference.delete();
      }
    } catch (e) { debugPrint('Failed to delete user mappings: $e'); }
    
    // 3. Delete pesantren doc itself
    await pesantrenRef.delete();
    notifyListeners();
  }

  Future<void> updateAdminPhoto(String path) async {
    if (currentUserId == null) return;
    _adminPhoto = path;
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'admin_photos', fileName: currentUserId!);
      _adminPhoto = cloudUrl;
      await firebase.setUserData(currentUserId!, {'photoPath': cloudUrl});
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to upload admin photo: $e");
    }
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
    musyrifList = musyrifList.map((m) {
      if (m.id == linkedMusyrifId) {
        return m.copyWith(photoPath: path);
      }
      return m;
    }).toList();
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'musyrif_photos', fileName: linkedMusyrifId!);
      await getCollection('musyrif').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Failed to upload musyrif photo: $e");
    }
  }

  Future<void> updatePengawasPhoto(String path) async {
    if (linkedMusyrifId == null) return;
    pengawasList = pengawasList.map((p) {
      if (p.id == linkedMusyrifId) {
        return p.copyWith(photoPath: path);
      }
      return p;
    }).toList();
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'pengawas_photos', fileName: linkedMusyrifId!);
      await getCollection('pengawas').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Failed to upload pengawas photo: $e");
    }
  }

  Future<void> updateSantriPhoto(String santriId, String path) async {
    santriList = santriList.map((s) {
      if (s.id == santriId) {
        return s.copyWith(photoPath: path);
      }
      return s;
    }).toList();
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'santri_photos', fileName: santriId);
      await getCollection('santri').doc(santriId).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Failed to upload santri photo: $e");
    }
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

  Future<void> loginAsTenantAdmin(String tenantId, String tenantNama) async {
    setLoginInfo(
      UserRole.admin,
      linkedSantriId: null,
      linkedMusyrifId: null,
      userId: currentUserId,
      pesantrenId: tenantId,
    );
    await setupFirestoreListeners();
    notifyListeners();
  }

  Future<void> switchBackToSuperAdmin() async {
    setLoginInfo(
      UserRole.superAdmin,
      linkedSantriId: null,
      linkedMusyrifId: null,
      userId: currentUserId,
      pesantrenId: null,
    );
    await setupFirestoreListeners();
    notifyListeners();
  }
}
