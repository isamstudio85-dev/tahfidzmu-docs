import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/santri.dart';
import '../models/musyrif_data.dart';
import '../models/halaqah_data.dart';
import '../models/kelas_data.dart';
import '../models/graduation_event.dart';
import '../models/graduation_registration.dart';
import '../models/pesantren_info.dart';
import '../models/setoran.dart';
import '../models/tasmi_record.dart';
import '../models/pengawas_data.dart';
import '../models/presensi_halaqah.dart';
import '../models/app_notification.dart';
import 'auth_mixin.dart';

mixin DataMixin on ChangeNotifier, AuthMixin {
  @override
  FirebaseFirestore get firestore;

  StreamSubscription? santriSub;
  StreamSubscription? musyrifSub;
  StreamSubscription? halaqahSub;
  StreamSubscription? kelasSub;
  StreamSubscription? eventSub;
  StreamSubscription? regSub;
  StreamSubscription? recentSetoransSub;
  StreamSubscription? pengawasSub;
  StreamSubscription? presensiSub;
  StreamSubscription? notificationSub;
  StreamSubscription? pondokKnowledgeSub;

  final Map<String, StreamSubscription> _setoranSubs = {};
  final Map<String, StreamSubscription> _tasmiSubs = {};

  List<Santri> santriList = [];
  List<MusyrifData> musyrifList = [];
  List<HalaqahData> halaqahList = [];
  List<KelasData> kelasList = [];
  List<GraduationEvent> graduationEvents = [];
  List<GraduationRegistration> graduationRegistrations = [];
  List<PengawasData> pengawasList = [];
  List<PresensiHalaqah> presensiList = [];
  List<AppNotification> notificationList = [];
  List<Map<String, dynamic>> pondokKnowledgeList = [];
  bool isPondokKnowledgeInitialized = false;
  
  PesantrenInfo pesantrenInfo = const PesantrenInfo(
    nama: 'Al-Furqon MBS Cibiuk',
    alamat: 'Jl. Pulobaru Desa Cibiuk Kaler Kec Cibiuk Garut',
    noTelp: '081289607738',
    email: 'info.alfurqonmbscibiuk@gmail.com',
  );

  String get pesantrenName => pesantrenInfo.nama;

  CollectionReference<Map<String, dynamic>> getCollection(String name) {
    if (pesantrenId != null) {
      return firestore.collection('pesantren').doc(pesantrenId).collection(name);
    }
    return firestore.collection(name);
  }

  Future<void> setupFirestoreListeners() async {
    cancelSubscriptions();

    final completers = <Completer>[];
    
    final santriCompleter = Completer();
    final halaqahCompleter = Completer();
    final musyrifCompleter = Completer();
    final kelasCompleter = Completer();
    
    completers.addAll([santriCompleter, halaqahCompleter, musyrifCompleter, kelasCompleter]);

    // ── 1. Unified Santri & Halaqah Subscription (Global for Ranking) ──────
    // To show ranking to everyone, we must fetch all santri and halaqahs.
    // However, we only attach deep listeners (subcollections) to relevant ones.

    // 1.1 All Santri (Basic Info)
    santriSub = getCollection('santri').snapshots().listen((snap) {
      final allSantri = snap.docs.map((doc) => Santri.fromJson(doc.data())).toList();
      
      if (isOrangTua) {
        // Keep santriList populated for ranking, but attach deep listener only to child
        santriList = allSantri;
        if (linkedSantriId != null) {
          _listenToSingleSantriSubcollections(linkedSantriId!);
        }
      } else if (isMusyrif) {
        // Keep santriList populated for ranking, but attach deep listeners only to halaqah
        santriList = allSantri;
        final myHalaqahIds = halaqahList.map((h) => h.id).toList();
        if (myHalaqahIds.isNotEmpty) {
          final mySantriList = allSantri.where((s) => myHalaqahIds.contains(s.halaqahId)).toList();
          _listenToMultipleSantriSubcollections(mySantriList);
        }
      } else {
        // Admin: listen to everything deep
        _listenToMultipleSantriSubcollections(allSantri);
      }
      
      if (!santriCompleter.isCompleted) santriCompleter.complete();
      notifyListeners();
    }, onError: (e) {
      if (!santriCompleter.isCompleted) santriCompleter.complete();
    });

    // 1.2 All Halaqahs (For Ranking & Statistics)
    halaqahSub = getCollection('halaqah').snapshots().listen((snap) {
      halaqahList = snap.docs.map((doc) => HalaqahData.fromJson(doc.data())).toList();
      if (!halaqahCompleter.isCompleted) halaqahCompleter.complete();
      notifyListeners();
    }, onError: (e) {
      if (!halaqahCompleter.isCompleted) halaqahCompleter.complete();
    });

    // ── 2. Role-specific recent activity ────────────────────────────────────
    recentSetoransSub?.cancel();
    if (isOrangTua) {
       // Parents don't need the collectionGroup listener for others
    } else if (isMusyrif) {
      // COORDINATOR SUPPORT: A coordinator might have many halaqahs.
      // Firebase 'whereIn' is limited to 10. We'll query pesantren-wide 
      // and filter in-memory for accuracy and stability.
      if (pesantrenId != null) {
        recentSetoransSub = firestore.collectionGroup('setoranHistory')
            .where('pesantrenId', isEqualTo: pesantrenId)
            .orderBy('date', descending: true)
            .limit(50) // Increased limit to ensure we find enough relevant ones
            .snapshots().listen((snap) {
          final myHalaqahIds = halaqahList.where((h) => h.musyrifId == currentUserId || (linkedMusyrif?.managedHalaqahIds.contains(h.id) ?? false)).map((h) => h.id).toSet();
          
          for (var doc in snap.docs) {
            final data = doc.data();
            final hId = data['halaqahId'] as String?;
            // Only add if it belongs to one of my managed halaqahs
            if (hId != null && myHalaqahIds.contains(hId)) {
              _addSetoranToSantriInMemory(SetoranRecord.fromJson(data));
            }
          }
        }, onError: (e) => debugPrint("Recent Setorans Sub Error: $e"));
      }
    } else {
      // Admin: listen to the 100 most recent records pesantren-wide
      Query<Map<String, dynamic>> query = firestore.collectionGroup('setoranHistory');
      if (pesantrenId != null) query = query.where('pesantrenId', isEqualTo: pesantrenId);
      recentSetoransSub = query.orderBy('date', descending: true).limit(100).snapshots().listen((snap) {
        for (var doc in snap.docs) {
          _addSetoranToSantriInMemory(SetoranRecord.fromJson(doc.data()));
        }
      });
    }

    // ── 2. Other Global Subscriptions ─────────────────────────────────────────
    musyrifSub = getCollection('musyrif').snapshots().listen((snap) {
      musyrifList = snap.docs.map((doc) => MusyrifData.fromJson(doc.data())).toList();
      if (!musyrifCompleter.isCompleted) musyrifCompleter.complete();
      notifyListeners();
    }, onError: (e) {
      if (!musyrifCompleter.isCompleted) musyrifCompleter.complete();
    });

    kelasSub = getCollection('kelas').snapshots().listen((snap) {
      kelasList = snap.docs.map((doc) => KelasData.fromJson(doc.data())).toList();
      if (!kelasCompleter.isCompleted) kelasCompleter.complete();
      notifyListeners();
    }, onError: (e) {
      if (!kelasCompleter.isCompleted) kelasCompleter.complete();
    });

    eventSub = getCollection('graduation_events').snapshots().listen((snap) {
      graduationEvents = snap.docs.map((doc) => GraduationEvent.fromJson(doc.data())).toList();
      notifyListeners();
    });

    regSub = getCollection('graduation_registrations').snapshots().listen((snap) {
      graduationRegistrations = snap.docs.map((doc) => GraduationRegistration.fromJson(doc.data())).toList();
      notifyListeners();
    });

    if (isAdmin) {
      pengawasSub = getCollection('pengawas').snapshots().listen((snap) {
        pengawasList = snap.docs.map((doc) => PengawasData.fromJson(doc.data())).toList();
        notifyListeners();
      }, onError: (e) {
        debugPrint("Error listening to pengawas: $e");
      });
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    presensiSub = getCollection('presensi')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .snapshots()
        .listen((snap) {
      presensiList = snap.docs.map((doc) => PresensiHalaqah.fromJson(doc.data())).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to presensi: $e");
    });

    if (currentUserId != null) {
      notificationSub = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snap) {
        notificationList = snap.docs.map((doc) => AppNotification.fromJson(doc.id, doc.data())).toList();
        notifyListeners();
      }, onError: (e) {
        debugPrint("Error listening to notifications: $e");
      });
    }
    
    getCollection('settings').doc('pesantren_info').get().then((doc) {
      if (doc.exists) {
        pesantrenInfo = PesantrenInfo.fromJson(doc.data()!);
        notifyListeners();
      }
    });

    pondokKnowledgeSub = getCollection('settings').doc('pondok_knowledge').snapshots().listen((doc) {
      if (doc.exists) {
        pondokKnowledgeList = List<Map<String, dynamic>>.from(doc.data()?['items'] ?? []);
        isPondokKnowledgeInitialized = true;
      } else {
        pondokKnowledgeList = [];
        isPondokKnowledgeInitialized = false;
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to pondok_knowledge: $e");
    });

    // Wait for initial essential data streams to yield at least one event before proceeding
    // Capped with a timeout to prevent bootstrapping hangs if there is no cached data and no network
    try {
      await Future.wait(completers.map((c) => c.future)).timeout(const Duration(milliseconds: 3000));
    } catch (e) {
      debugPrint("setupFirestoreListeners wait initial data timed out: $e");
    }
  }

  void _listenToSingleSantriSubcollections(String sId) {
    _setoranSubs[sId]?.cancel();
    _setoranSubs[sId] = getCollection('santri').doc(sId).collection('setoranHistory')
        .orderBy('date', descending: false)
        .snapshots().listen((snap) {
      final history = snap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();
      _updateSantriHistoryInMemory(sId, history: history);
    });

    _tasmiSubs[sId]?.cancel();
    _tasmiSubs[sId] = getCollection('santri').doc(sId).collection('tasmiHistory')
        .orderBy('date', descending: false)
        .snapshots().listen((snap) {
      final history = snap.docs.map((doc) => TasmiRecord.fromJson(doc.data())).toList();
      _updateSantriHistoryInMemory(sId, tasmi: history);
    });
  }

  void _listenToMultipleSantriSubcollections(List<Santri> baseList) {
    final activeIds = baseList.map((s) => s.id).toSet();

    _setoranSubs.keys.toList().forEach((id) {
      if (!activeIds.contains(id)) {
        _setoranSubs[id]?.cancel();
        _setoranSubs.remove(id);
      }
    });
    _tasmiSubs.keys.toList().forEach((id) {
      if (!activeIds.contains(id)) {
        _tasmiSubs[id]?.cancel();
        _tasmiSubs.remove(id);
      }
    });

    santriList = baseList.map((s) {
      // Retain the existing in-memory history (e.g. recent setoran records loaded for dashboard)
      // if we are not actively streaming their deep history via a detail screen.
      final existingSantri = santriList.firstWhere((x) => x.id == s.id, orElse: () => s);
      final existingSetorans = _setoranSubs.containsKey(s.id) ? s.setoranHistory : existingSantri.setoranHistory;
      final existingTasmis = _tasmiSubs.containsKey(s.id) ? s.tasmiHistory : existingSantri.tasmiHistory;
      return s.copyWith(setoranHistory: existingSetorans, tasmiHistory: existingTasmis);
    }).toList();
    notifyListeners();
  }

  void _updateSantriHistoryInMemory(String sId, {List<SetoranRecord>? history, List<TasmiRecord>? tasmi}) {
    santriList = santriList.map((s) {
      if (s.id == sId) {
        return s.copyWith(
          setoranHistory: history ?? s.setoranHistory,
          tasmiHistory: tasmi ?? s.tasmiHistory,
        );
      }
      return s;
    }).toList();
    notifyListeners();
  }

  void cancelAllSubcollectionSubscriptions() {
    for (var sub in _setoranSubs.values) {
      sub.cancel();
    }
    _setoranSubs.clear();
    for (var sub in _tasmiSubs.values) {
      sub.cancel();
    }
    _tasmiSubs.clear();
  }

  void listenToActiveSantriHistory(String santriId) {
    _listenToSingleSantriSubcollections(santriId);
  }

  Future<void> fetchSantriHistoryOnce(String santriId) async {
    final setoranSnap = await getCollection('santri').doc(santriId).collection('setoranHistory').get();
    final setoranList = setoranSnap.docs.map((doc) => SetoranRecord.fromJson(doc.data())).toList();

    final tasmiSnap = await getCollection('santri').doc(santriId).collection('tasmiHistory').get();
    final tasmiList = tasmiSnap.docs.map((doc) => TasmiRecord.fromJson(doc.data())).toList();

    _updateSantriHistoryInMemory(santriId, history: setoranList, tasmi: tasmiList);
  }

  void stopListeningToActiveSantriHistory(String santriId) {
    if (isOrangTua && santriId == linkedSantriId) return; // Keep parent child listener active
    
    _setoranSubs[santriId]?.cancel();
    _setoranSubs.remove(santriId);
    _tasmiSubs[santriId]?.cancel();
    _tasmiSubs.remove(santriId);
  }

  void clearData() {
    santriList = [];
    musyrifList = [];
    halaqahList = [];
    kelasList = [];
    graduationEvents = [];
    graduationRegistrations = [];
    pengawasList = [];
    presensiList = [];
    notificationList = [];
    pondokKnowledgeList = [];
    isPondokKnowledgeInitialized = false;
  }

  void cancelSubscriptions() {
    santriSub?.cancel();
    musyrifSub?.cancel();
    halaqahSub?.cancel();
    kelasSub?.cancel();
    eventSub?.cancel();
    regSub?.cancel();
    recentSetoransSub?.cancel();
    pengawasSub?.cancel();
    presensiSub?.cancel();
    notificationSub?.cancel();
    pondokKnowledgeSub?.cancel();
    cancelAllSubcollectionSubscriptions();
  }

  void _addSetoranToSantriInMemory(SetoranRecord record) {
    santriList = santriList.map((s) {
      if (s.id == record.santriId) {
        if (!s.setoranHistory.any((r) => r.id == record.id)) {
          final newHistory = [...s.setoranHistory, record]..sort((a, b) => b.date.compareTo(a.date));
          return s.copyWith(setoranHistory: newHistory);
        }
      }
      return s;
    }).toList();
    notifyListeners();
  }

  Santri? getSantriById(String? id) {
    if (id == null) return null;
    try { return santriList.firstWhere((s) => s.id == id); } catch (_) { return null; }
  }

  MusyrifData? getMusyrifById(String? id) {
    if (id == null) return null;
    try { return musyrifList.firstWhere((m) => m.id == id); } catch (_) { return null; }
  }

  HalaqahData? getHalaqahById(String? id) {
    if (id == null) return null;
    try { return halaqahList.firstWhere((h) => h.id == id); } catch (_) { return null; }
  }

  List<Santri> getSantriByHalaqah(String halaqahId) => santriList.where((s) => s.halaqahId == halaqahId).toList();
  
  List<Santri> getSantriByMusyrif(String musyrifId) {
    final m = getMusyrifById(musyrifId);
    final Set<String> halaqahIds = halaqahList.where((h) => h.musyrifId == musyrifId).map((h) => h.id).toSet();
    
    // Add halaqahs explicitly managed by coordinator
    if (m?.isKoordinator == true) {
      halaqahIds.addAll(m!.managedHalaqahIds);
    }

    return santriList.where((s) => halaqahIds.contains(s.halaqahId)).toList();
  }

  GraduationRegistration? getRegistration(String eventId, String santriId) {
    try { return graduationRegistrations.firstWhere((r) => r.eventId == eventId && r.santriId == santriId); } catch (_) { return null; }
  }

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

  String? getTodaySantriStatus(String santriId) {
    final now = DateTime.now();
    for (var p in presensiList) {
      if (p.tanggal.year == now.year && p.tanggal.month == now.month && p.tanggal.day == now.day) {
        if (p.daftarHadir.containsKey(santriId)) {
          return p.daftarHadir[santriId];
        }
      }
    }
    return null;
  }
}
