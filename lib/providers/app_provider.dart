import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/surah_model.dart';
import '../models/user_role.dart';
import '../models/tasmi_record.dart';
import '../models/setoran_continuation.dart';
import '../models/presensi_halaqah.dart';
import '../models/app_notification.dart';
import '../models/error_mark.dart';
import '../services/quran_service.dart';

import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/core/utils/quran_juz_utils.dart';
import '../services/login_preferences_service.dart';

import 'auth_mixin.dart';
import 'data_mixin.dart';
import 'session_mixin.dart';
import 'management_mixin.dart';

class AppProvider extends ChangeNotifier
    with AuthMixin, DataMixin, SessionMixin, ManagementMixin {
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

  String generateId(String collectionName) => getCollection(collectionName).doc().id;

  AppProvider() { initialize(); }

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    notifyListeners();
    try {
      await _fetchSurahList();
      final user = firebase.currentUser;
      if (user != null) {
        final userData = await firebase.getUserData(user.uid);
        if (userData != null) {
          if (userData['role'] == 'superAdmin' || user.email == 'dasamsamsudin87@gmail.com') {
            loginError = 'Login super admin hanya tersedia di web admin.';
            await performLogout();
            return;
          }
          setLoginInfo(
            roleFromString(userData['role'] ?? '') ?? UserRole.orangTua,
            linkedSantriId: userData['linkedId'] as String?,
            linkedMusyrifId: userData['linkedId'] as String?,
            userId: user.uid,
            pesantrenId: userData['pesantrenId'] as String?,
          );
          currentUsername = userData['username'] as String?;
          if (isAdmin) adminPhoto = userData['photoPath'] ?? '';
          
          // AUTO-CLEANUP: Clear any stuck live sessions for THIS user on startup
          await endSetoranSession();

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
      surahList = await QuranService.getSurahList();
    } catch (e) {
      surahListError = e.toString();
    } finally {
      isSurahListLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSurahList() => _fetchSurahList();

  void clearLoginError() { loginError = null; notifyListeners(); }

  Future<void> loadSurahForReader(int surahNumber) async {
    activeSetoranSurahNumber = surahNumber;
    final surahInfo = surahList.firstWhere((s) => s.number == surahNumber, orElse: () => surahList.first);
    activeSetoranSurahName = surahInfo.name;
    activeSetoranSurahEnglishName = surahInfo.englishName;
    isSurahLoading = true;
    notifyListeners();
    try {
      currentSurah = await QuranService.getSurah(surahNumber);
      if (surahNumber < 114) QuranService.getSurah(surahNumber + 1);
    } catch (e) {
      surahLoadError = e.toString();
    } finally {
      isSurahLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithCredentials(String? targetPesantrenId, String username, String password, {bool qrLogin = false}) async {
    loginError = null;
    final String u = username.trim();
    String p = password.trim();
    try {
      if (targetPesantrenId == null || targetPesantrenId.trim().isEmpty) {
        loginError = 'Login super admin di Android dinonaktifkan.';
        return false;
      }
      final String email = u.contains('@') ? u : '$u.$targetPesantrenId@tahfidzmu.com'.toLowerCase().replaceAll(' ', '');
      if (email == 'dasamsamsudin87@gmail.com') { loginError = 'Login super admin hanya di web.'; return false; }

      final mappingCollection = firestore.collection('pesantren').doc(targetPesantrenId).collection('user_mappings');
      DocumentSnapshot<Map<String, dynamic>>? mappingDoc;
      try { 
        mappingDoc = await mappingCollection.doc(u).get().timeout(const Duration(seconds: 5)); 
      } catch (_) {
        mappingDoc = await mappingCollection.doc(u).get(const GetOptions(source: Source.cache));
      }
      
      if (!mappingDoc.exists) {
        final normalized = normalizeLoginKey(u);
        if (normalized != u) {
          mappingDoc = await mappingCollection.doc(normalized).get();
        }
      }

      final String effectiveUsername = mappingDoc.exists ? mappingDoc.id : u;

      UserCredential? cred;
      try {
        // 1. Attempt primary sign-in with EXACT provided password
        cred = await firebase.signIn(email, p);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        
        // 2. Handle First-Time Auto-Provisioning (Excel Imports)
        // If sign-in failed, check if the account doesn't exist in Auth and we should create it
        if (mappingDoc.exists && (errStr.contains('user-not-found') || errStr.contains('invalid-credential'))) {
          final expectedInitialPassword = (mappingDoc.data()?['defaultPassword'] as String?) ?? effectiveUsername;
          
          // Only create if the user provided the CORRECT initial password from mapping
          if (p == expectedInitialPassword) {
            try {
              cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: p);
            } catch (createErr) {
               // If creation fails with already-in-use, it means the Auth account exists but p was wrong
               // or there is a ghost account.
               if (createErr.toString().contains('already-in-use')) {
                 loginError = 'Kata sandi salah atau akun memerlukan perbaikan Admin.';
                 return false;
               }
            }
          }
        }
      }

      final user = cred?.user;
      if (user == null) { 
        loginError ??= 'Username atau sandi salah.'; 
        return false; 
      }

      if (mappingDoc.exists) {
        final mData = mappingDoc.data()!;
        await firebase.setUserData(user.uid, {
          'role': mData['role'],
          'linkedId': mData['linkedId'],
          'username': effectiveUsername,
          'pesantrenId': targetPesantrenId,
        });
        if (mData['mustResetAuth'] == true) {
           await getCollection('user_mappings').doc(effectiveUsername).update({'mustResetAuth': false});
        }
      }

      final userData = await firebase.getUserData(user.uid);
      if (userData == null) { loginError = 'Data pengguna tidak ditemukan.'; return false; }

      setLoginInfo(roleFromString(userData['role'] as String) ?? UserRole.orangTua, linkedSantriId: userData['linkedId'] as String?, linkedMusyrifId: userData['linkedId'] as String?, userId: user.uid, pesantrenId: userData['pesantrenId'] as String?);
      currentUsername = effectiveUsername;
      currentPassword = p;
      if (isAdmin) adminPhoto = userData['photoPath'] ?? '';
      await setupFirestoreListeners();

      final displayName = isOrangTua ? (linkedSantri?.name ?? u) : (isMusyrif ? (linkedMusyrif?.nama ?? u) : 'Admin');
      final photoPath = isOrangTua ? linkedSantri?.photoPath : (isMusyrif ? linkedMusyrif?.photoPath : null);

      try {
        await LoginPreferencesService.saveAccount(SavedAccount(username: u, password: p, pesantrenId: targetPesantrenId, displayName: displayName, photoPath: photoPath, role: userData['role'] as String, linkedId: userData['linkedId'] as String?));
      } catch (_) {}
      return true;
    } catch (e) {
      loginError ??= 'Gagal masuk. Periksa jaringan Anda.';
      return false;
    }
  }

  Future<bool> switchAccount(SavedAccount account) async {
    _isInitializing = true;
    notifyListeners();
    try {
      await firebase.signOut();
      return await loginWithCredentials(account.pesantrenId, account.username, account.password);
    } catch (_) { return false; } finally { _isInitializing = false; notifyListeners(); }
  }

  Future<void> updateSetoranRecord(String santriId, SetoranRecord record) async {
    final setoranJson = record.toJson();
    if (pesantrenId != null) setoranJson['pesantrenId'] = pesantrenId;
    await getCollection('santri').doc(santriId).collection('setoranHistory').doc(record.id).set(setoranJson);
    final now = DateTime.now();
    if (record.date.year == now.year && record.date.month == now.month && record.date.day == now.day) {
      await setSantriKehadiranStatus(santriId, 'setoran');
    }
    await triggerSetoranNotification(santriId, record);
    
    // INCREMENTAL UPDATE: Don't fetch all history. Update aggregate fields directly.
    final targetSantri = getSantriById(santriId);
    if (targetSantri != null) {
      final int currentCount = targetSantri.totalSetoranCount;
      final double currentAvg = targetSantri.averageScore;
      final double newAvg = ((currentAvg * currentCount) + record.finalScore) / (currentCount + 1);
      
      final currentZiyadah = targetSantri.totalZiyadahAyahs;
      final currentMurojaah = targetSantri.totalMurojaahAyahs;
      
      int addedZiyadah = 0;
      int addedMurojaah = 0;
      if (record.type == SetoranType.ziyadah) {
        addedZiyadah = record.passedAyahs.length;
      } else {
        addedMurojaah = record.passedAyahs.length;
      }

      final Set<int> juzSet = Set.from(targetSantri.juzCoveredByZiyadah);
      if (record.type == SetoranType.ziyadah) {
        final jStart = QuranJuzUtils.juzOf(record.surahNumber, record.ayahStart);
        final jEnd = QuranJuzUtils.juzOf(record.surahNumber, record.ayahEnd);
        for (int j = jStart; j <= jEnd; j++) {
          juzSet.add(j);
        }
      }

      final double newEstimatedJuz = targetSantri.initialMemorizedJuz.length + ((currentZiyadah + addedZiyadah) / 604.0);

      await getCollection('santri').doc(santriId).update({
        'averageScore': newAvg,
        'totalSetoranCount': currentCount + 1,
        'totalErrors': FieldValue.increment(record.totalErrors),
        'totalZiyadahAyahs': currentZiyadah + addedZiyadah,
        'totalMurojaahAyahs': currentMurojaah + addedMurojaah,
        'totalFailedAyahs': FieldValue.increment(record.failedAyahs.length),
        'estimatedJuz': newEstimatedJuz,
        'juzCoveredByZiyadah': juzSet.toList()..sort(),
        'lastSetoranAt': record.date.toIso8601String(),
      });
    }
    notifyListeners();
  }

  Future<void> deleteSetoranRecord(String santriId, String recordId) async {
    // Note: Deletion still needs a full re-calc for absolute accuracy if we don't have the old record's values easily
    await getCollection('santri').doc(santriId).collection('setoranHistory').doc(recordId).delete();
    final targetSantri = getSantriById(santriId);
    if (targetSantri != null) {
      final historySnap = await getCollection('santri').doc(santriId).collection('setoranHistory').get();
      final allRecords = historySnap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();
      final tempSantri = targetSantri.copyWith(setoranHistory: allRecords);
      
      final lastDate = allRecords.isEmpty ? null : allRecords.first.date.toIso8601String();

      await getCollection('santri').doc(santriId).update({
        'averageScore': tempSantri.averageScore, 
        'totalSetoranCount': tempSantri.totalSetoranCount, 
        'totalErrors': tempSantri.totalErrors, 
        'totalZiyadahAyahs': tempSantri.totalZiyadahAyahs, 
        'totalMurojaahAyahs': tempSantri.totalMurojaahAyahs, 
        'totalFailedAyahs': tempSantri.totalFailedAyahs, 
        'estimatedJuz': tempSantri.estimatedJuz, 
        'juzCoveredByZiyadah': tempSantri.juzCoveredByZiyadah,
        'lastSetoranAt': lastDate,
      });
    }
    notifyListeners();
  }

  @override
  Future<void> performLogout() async { try { cancelSubscriptions(); } catch (_) {} await super.performLogout(); }

  @override
  void dispose() { cancelSubscriptions(); super.dispose(); }

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    notifyListeners();
    try {
      // 1. SILENT CLEANUP: Trigger firestore cleanup without 'awaiting' it too long
      // This prevents the UI from being stuck if the network is slow.
      endSetoranSession().timeout(const Duration(seconds: 1), onTimeout: () {});

      // 2. DISCONNECT: Stop all listeners immediately
      cancelSubscriptions();
      
      // 3. WIPE: Clear all sensitive data in memory
      clearData();
      stopSetoranSession();
      
      // 4. AUTH EXIT: Perform final sign out and state clearing
      await performLogout();
    } catch (e) {
      debugPrint("Logout error: $e");
      // Force logout even on error to prevent being stuck in blank screen
      await performLogout();
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  @override
  void startSetoranSession({required Santri santri, required SetoranType type, required SurahInfo surah, required int ayahStart, required int ayahEnd}) {
    super.startSetoranSession(santri: santri, type: type, surah: surah, ayahStart: ayahStart, ayahEnd: ayahEnd);
    _writeActiveSessionToFirestore(santriName: santri.name, detail: '${type.label}: ${surah.englishName} $ayahStart-$ayahEnd');
  }

  @override
  void startTasmiSession({required Santri santri, required List<int> juzNumbers, required String year}) {
    super.startTasmiSession(santri: santri, juzNumbers: juzNumbers, year: year);
    _writeActiveSessionToFirestore(santriName: santri.name, detail: 'Tasmi\' Juz [${juzNumbers.join(', ')}]');
  }

  Future<void> _writeActiveSessionToFirestore({required String santriName, required String detail}) async {
    final sId = currentUserId;
    if (sId == null) return;
    try {
      final String name = linkedMusyrif?.nama ?? (isAdmin ? 'Admin' : 'Musyrif');
      final sessionJson = {
        'id': sId, 
        'musyrifId': linkedMusyrifId ?? sId, 
        'musyrifName': name, 
        'santriName': santriName, 
        'detail': detail, 
        'startedAt': FieldValue.serverTimestamp()
      };
      if (pesantrenId != null) sessionJson['pesantrenId'] = pesantrenId!;
      await getCollection('active_sessions').doc(sId).set(sessionJson);
      debugPrint("Live session written for $name");
    } catch (e) {
      debugPrint("Failed to write live session: $e");
    }
  }

  Future<void> endSetoranSession() async {
    if (currentUserId != null) {
      try { await getCollection('active_sessions').doc(currentUserId!).delete(); } catch (_) {}
    }
    activeSetoranSantri = null;
    clearErrors();
  }

  Future<void> updatePondokKnowledge(List<Map<String, dynamic>> items) async {
    pondokKnowledgeList = items;
    isPondokKnowledgeInitialized = true;
    await getCollection('settings').doc('pondok_knowledge').set({'items': items, 'initialized': true});
    notifyListeners();
  }

  Future<void> initializePondokKnowledge(List<Map<String, dynamic>> items) async {
    pondokKnowledgeList = items;
    isPondokKnowledgeInitialized = true;
    await getCollection('settings').doc('pondok_knowledge').set({'items': items, 'initialized': true});
    notifyListeners();
  }

  Future<void> triggerSetoranNotification(String santriId, SetoranRecord record) async {
    final santri = getSantriById(santriId);
    if (santri == null) return;
    try {
      // Find all users linked to this santri (Orang Tua) within the same pesantren
      final snap = await firestore.collection('users')
          .where('role', isEqualTo: 'orangTua')
          .where('linkedId', isEqualTo: santriId)
          .where('pesantrenId', isEqualTo: pesantrenId)
          .get();

      for (var doc in snap.docs) {
        final title = "Setoran Baru: ${record.surahEnglishName}";
        final body = "${santri.name} baru saja menyetor hafalan dengan nilai ${record.finalScore.toStringAsFixed(0)}.";
        await sendNotification(doc.id, title, body, 'setoran', metadata: {'santriId': santriId, 'recordId': record.id});
      }

      // Also notify Admins of this pesantren
      final adminSnap = await firestore.collection('users')
          .where('role', isEqualTo: 'admin')
          .where('pesantrenId', isEqualTo: pesantrenId)
          .get();
      
      for (var doc in adminSnap.docs) {
        if (doc.id == currentUserId) continue; // Don't notify self
        final title = "Update Hafalan: ${santri.name}";
        final body = "Setoran baru: ${record.surahEnglishName} (${record.ayahRange}). Skor: ${record.finalScore.toStringAsFixed(0)}.";
        await sendNotification(doc.id, title, body, 'setoran', metadata: {'santriId': santriId, 'recordId': record.id});
      }
    } catch (e) {
      debugPrint("Failed to trigger setoran notification: $e");
    }
  }

  Future<void> triggerPresensiNotification(String santriId, String status) async {
    final santri = getSantriById(santriId);
    if (santri == null) return;
    
    String statusLabel;
    switch (status) {
      case 'setoran': statusLabel = "Hadir & Setoran"; break;
      case 'sakit': statusLabel = "Sakit"; break;
      case 'izin': statusLabel = "Izin"; break;
      case 'alfa': statusLabel = "Alfa"; break;
      case 'ditunda': statusLabel = "Hadir (Belum Setoran)"; break;
      default: statusLabel = status;
    }

    try {
      final snap = await firestore.collection('users')
          .where('role', isEqualTo: 'orangTua')
          .where('linkedId', isEqualTo: santriId)
          .where('pesantrenId', isEqualTo: pesantrenId)
          .get();

      for (var doc in snap.docs) {
        final title = "Kehadiran Halaqah: ${santri.name}";
        final body = "Status hari ini: $statusLabel.";
        await sendNotification(doc.id, title, body, 'presensi', metadata: {'santriId': santriId});
      }
    } catch (e) {
      debugPrint("Failed to trigger presensi notification: $e");
    }
  }

  Future<void> setSantriKehadiranStatus(String santriId, String status) async {
    final santri = getSantriById(santriId);
    if (santri == null || santri.halaqahId == null) return;
    final halaqah = getHalaqahById(santri.halaqahId);
    final now = DateTime.now();
    final docId = "${santri.halaqahId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final docRef = getCollection('presensi').doc(docId);
    final docSnap = await docRef.get();
    
    if (docSnap.exists) {
      final updatedDaftar = Map<String, String>.from(docSnap.data()!['daftarHadir'] ?? {});
      updatedDaftar[santriId] = status;
      await docRef.update({'daftarHadir': updatedDaftar, 'waktuSubmit': Timestamp.fromDate(now)});
    } else {
      final newPresensi = PresensiHalaqah(
        id: docId, 
        halaqahId: santri.halaqahId!, 
        halaqahNama: halaqah?.nama ?? '', 
        musyrifId: halaqah?.musyrifId ?? '', 
        musyrifNama: getMusyrifById(halaqah?.musyrifId)?.nama ?? '', 
        tanggal: DateTime(now.year, now.month, now.day), 
        waktuSubmit: now, 
        daftarHadir: {santriId: status}
      );
      await docRef.set(newPresensi.toJson());
    }

    // Trigger Notification for Parents
    await triggerPresensiNotification(santriId, status);
  }

  Future<void> sendNotification(String targetUserId, String title, String body, String type, {Map<String, dynamic>? metadata}) async {
    final ref = firestore.collection('users').doc(targetUserId).collection('notifications').doc();
    final notif = AppNotification(id: ref.id, title: title, body: body, timestamp: DateTime.now(), targetUserId: targetUserId, type: type, metadata: metadata);
    await ref.set(notif.toJson());
  }

  Future<void> markAllNotificationsAsRead() async {
    if (currentUserId == null) return;
    final snap = await firestore.collection('users').doc(currentUserId).collection('notifications').where('isRead', isEqualTo: false).get();
    final batch = firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) return;
    await firestore.collection('users').doc(currentUserId).collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<SetoranRecord?> completeSetoran(int fluencyRating) async {
    if (activeSetoranSantri == null) return null;
    final record = SetoranRecord(
      id: getCollection('santri').doc().id,
      santriId: activeSetoranSantri!.id,
      type: activeSetoranType,
      surahNumber: activeSetoranSurahNumber,
      surahName: activeSetoranSurahName,
      surahEnglishName: activeSetoranSurahEnglishName,
      ayahStart: activeSetoranAyahStart,
      ayahEnd: sessionPassedAyahs.isNotEmpty ? sessionPassedAyahs.reduce((a, b) => a > b ? a : b) : activeSetoranAyahEnd,
      passedAyahs: sessionPassedAyahs.toList(),
      failedAyahs: sessionFailedAyahs.toList(),
      errorMarks: sessionErrors.values.toList(),
      fluencyRating: fluencyRating,
      date: DateTime.now(),
      finalScore: ScoringUtils.calculateScore(errorMarks: sessionErrors.values.toList(), fluencyRating: fluencyRating),
    );
    await updateSetoranRecord(activeSetoranSantri!.id, record);
    await endSetoranSession();
    return record;
  }

  /// Saves a setoran directly from manual inputs (Quick Mode)
  Future<SetoranRecord?> saveManualSetoran({
    required Santri santri,
    required SetoranType type,
    required SurahInfo surah,
    required int ayahStart,
    required int ayahEnd,
    required int tajwidErrors,
    required int makhrojErrors,
    required int fluencyRating,
  }) async {
    // Generate dummy error marks to satisfy the model and scoring utility
    // These marks don't have word indices/text since it's a manual aggregate
    final List<ErrorMark> manualErrors = [];
    for (int i = 0; i < tajwidErrors; i++) {
      manualErrors.add(ErrorMark(
        wordKey: 'manual_t_$i', 
        errorType: ErrorType.tajwid, 
        surahNumber: surah.number, 
        ayahNumber: ayahStart, 
        wordIndex: -1, 
        word: '[Manual]'
      ));
    }
    for (int i = 0; i < makhrojErrors; i++) {
      manualErrors.add(ErrorMark(
        wordKey: 'manual_m_$i', 
        errorType: ErrorType.makhroj, 
        surahNumber: surah.number, 
        ayahNumber: ayahStart, 
        wordIndex: -1, 
        word: '[Manual]'
      ));
    }

    final record = SetoranRecord(
      id: getCollection('santri').doc().id,
      santriId: santri.id,
      type: type,
      surahNumber: surah.number,
      surahName: surah.name,
      surahEnglishName: surah.englishName,
      ayahStart: ayahStart,
      ayahEnd: ayahEnd,
      passedAyahs: List.generate(ayahEnd - ayahStart + 1, (index) => ayahStart + index),
      failedAyahs: [],
      errorMarks: manualErrors,
      fluencyRating: fluencyRating,
      date: DateTime.now(),
      finalScore: ScoringUtils.calculateScore(errorMarks: manualErrors, fluencyRating: fluencyRating),
    );

    await updateSetoranRecord(santri.id, record);
    notifyListeners();
    return record;
  }

  Future<void> triggerTasmiNotification(String santriId, TasmiRecord record) async {
    final santri = getSantriById(santriId);
    if (santri == null) return;
    try {
      final snap = await firestore.collection('users')
          .where('role', isEqualTo: 'orangTua')
          .where('linkedId', isEqualTo: santriId)
          .where('pesantrenId', isEqualTo: pesantrenId)
          .get();

      for (var doc in snap.docs) {
        final title = "Hasil Ujian Tasmi': ${santri.name}";
        final body = "Anak Anda telah menyelesaikan ujian Juz ${record.juzNumbers.join(', ')} dengan skor ${record.finalScore.toStringAsFixed(0)}.";
        await sendNotification(doc.id, title, body, 'setoran', metadata: {'santriId': santriId, 'tasmiId': record.id});
      }
    } catch (e) {
      debugPrint("Failed to trigger tasmi notification: $e");
    }
  }

  Future<TasmiRecord?> completeTasmi({required List<int> juzNumbers, required int fluencyRating, required String year, String status = 'lulus', String? note}) async {
    if (activeSetoranSantri == null) return null;
    final record = TasmiRecord(
      id: getCollection('santri').doc().id,
      santriId: activeSetoranSantri!.id,
      juzNumbers: juzNumbers,
      finalScore: ScoringUtils.calculateScore(errorMarks: sessionErrors.values.toList(), fluencyRating: fluencyRating),
      fluencyRating: fluencyRating,
      errorMarks: sessionErrors.values.toList(),
      date: DateTime.now(),
      status: status,
      year: year,
      note: note,
    );
    final tasmiJson = record.toJson();
    if (pesantrenId != null) tasmiJson['pesantrenId'] = pesantrenId;
    await getCollection('santri').doc(activeSetoranSantri!.id).collection('tasmiHistory').doc(record.id).set(tasmiJson);
    
    // Trigger Notification
    await triggerTasmiNotification(activeSetoranSantri!.id, record);

    await endSetoranSession();
    return record;
  }

  /// Prepares the reader state for reviewing a past setoran without triggering a live session
  void prepareReaderForReview({required Santri santri, required SetoranRecord record}) {
    activeSetoranSantri = santri;
    activeSetoranType = record.type;
    activeSetoranSurahNumber = record.surahNumber;
    activeSetoranSurahName = record.surahName;
    activeSetoranSurahEnglishName = record.surahEnglishName;
    activeSetoranAyahStart = record.ayahStart;
    activeSetoranAyahEnd = record.ayahEnd;
    
    // Load recorded data into session state for display
    sessionPassedAyahs.clear();
    sessionPassedAyahs.addAll(record.passedAyahs);
    
    sessionFailedAyahs.clear();
    sessionFailedAyahs.addAll(record.failedAyahs);
    
    sessionErrors.clear();
    for (var e in record.errorMarks) {
      sessionErrors[e.wordKey] = e;
    }
    
    notifyListeners();
  }

  Future<String> getLoginQrData(String userId) async {
    final snap = await getCollection('user_mappings').where('linkedId', isEqualTo: userId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final pwd = doc.data()['defaultPassword'] ?? doc.id;
      return 'tahfidzmu:login:$pesantrenId:${doc.id}:$pwd';
    }
    return 'tahfidzmu:login:$pesantrenId:$userId:$userId';
  }

  Future<bool> changeOwnPassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      if (currentUsername != null && pesantrenId != null) {
        try { await getCollection('user_mappings').doc(currentUsername!).update({'defaultPassword': newPassword}); } catch (_) {}
      }
      currentPassword = newPassword;
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  dynamic getYearlyTarget(String santriId) => null;

  SetoranContinuation? getNextSetoranSuggestion(String santriId) {
    final santri = getSantriById(santriId);
    if (santri == null || santri.setoranHistory.isEmpty) return null;
    final last = santri.setoranHistory.first;
    final lastSurah = last.surahNumber;
    final lastAyah = last.ayahEnd;
    final currentSurahInfo = surahList.firstWhere((s) => s.number == lastSurah, orElse: () => surahList.first);
    if (lastAyah < currentSurahInfo.numberOfAyahs) {
      return SetoranContinuation(surah: currentSurahInfo, ayahStart: lastAyah + 1, ayahEnd: (lastAyah + 10).clamp(lastAyah + 1, currentSurahInfo.numberOfAyahs), type: last.type);
    } else if (lastSurah < 114) {
      final nextSurah = surahList.firstWhere((s) => s.number == lastSurah + 1);
      return SetoranContinuation(surah: nextSurah, ayahStart: 1, ayahEnd: 10.clamp(1, nextSurah.numberOfAyahs), type: last.type);
    }
    return null;
  }

  Future<void> updateTasmiStatus(String registrationId, String status) async {
     try { 
       await getCollection('graduation_registrations').doc(registrationId).update({'status': status}); 
       
       // Notify Orang Tua about status update
       final regDoc = await getCollection('graduation_registrations').doc(registrationId).get();
       if (regDoc.exists) {
         final santriId = regDoc.data()?['santriId'] as String?;
         final eventTitle = regDoc.data()?['eventTitle'] as String? ?? 'Wisuda';
         if (santriId != null) {
           final santri = getSantriById(santriId);
           final snap = await firestore.collection('users')
               .where('role', isEqualTo: 'orangTua')
               .where('linkedId', isEqualTo: santriId)
               .where('pesantrenId', isEqualTo: pesantrenId)
               .get();

           for (var doc in snap.docs) {
             final title = "Status Ujian: ${santri?.name ?? 'Santri'}";
             final body = "Update status untuk $eventTitle: ${status.toUpperCase()}.";
             await sendNotification(doc.id, title, body, 'peringatan', metadata: {'santriId': santriId});
           }
         }
       }
     } catch (_) {}
  }

  /// Helper for tests or manual state injection (Not for production login)
  void login(UserRole role, {String? linkedSantriId, String? linkedMusyrifId, String? pesantrenId}) {
    setLoginInfo(role, linkedSantriId: linkedSantriId, linkedMusyrifId: linkedMusyrifId, pesantrenId: pesantrenId);
  }
}
