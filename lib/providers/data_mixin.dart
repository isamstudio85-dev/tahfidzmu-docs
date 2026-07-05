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

mixin DataMixin on ChangeNotifier {
  FirebaseFirestore get firestore;

  StreamSubscription? santriSub;
  StreamSubscription? musyrifSub;
  StreamSubscription? halaqahSub;
  StreamSubscription? kelasSub;
  StreamSubscription? eventSub;
  StreamSubscription? regSub;

  List<Santri> santriList = [];
  List<MusyrifData> musyrifList = [];
  List<HalaqahData> halaqahList = [];
  List<KelasData> kelasList = [];
  List<GraduationEvent> graduationEvents = [];
  List<GraduationRegistration> graduationRegistrations = [];
  
  PesantrenInfo pesantrenInfo = const PesantrenInfo(
    nama: 'Al-Furqon MBS Cibiuk',
    alamat: 'Jl. Pulobaru Desa Cibiuk Kaler Kec Cibiuk Garut',
    noTelp: '081289607738',
    email: 'info.alfurqonmbscibiuk@gmail.com',
  );

  String get pesantrenName => pesantrenInfo.nama;

  void setupFirestoreListeners() {
    cancelSubscriptions();
    santriSub = firestore.collection('santri').snapshots().listen((snap) {
      santriList = snap.docs.map((doc) => Santri.fromJson(doc.data())).toList();
      notifyListeners();
    });
    musyrifSub = firestore.collection('musyrif').snapshots().listen((snap) {
      musyrifList = snap.docs.map((doc) => MusyrifData.fromJson(doc.data())).toList();
      notifyListeners();
    });
    halaqahSub = firestore.collection('halaqah').snapshots().listen((snap) {
      halaqahList = snap.docs.map((doc) => HalaqahData.fromJson(doc.data())).toList();
      notifyListeners();
    });
    kelasSub = firestore.collection('kelas').snapshots().listen((snap) {
      kelasList = snap.docs.map((doc) => KelasData.fromJson(doc.data())).toList();
      notifyListeners();
    });
    eventSub = firestore.collection('graduation_events').snapshots().listen((snap) {
      graduationEvents = snap.docs.map((doc) => GraduationEvent.fromJson(doc.data())).toList();
      notifyListeners();
    });
    regSub = firestore.collection('graduation_registrations').snapshots().listen((snap) {
      graduationRegistrations = snap.docs.map((doc) => GraduationRegistration.fromJson(doc.data())).toList();
      notifyListeners();
    });
    
    firestore.collection('settings').doc('pesantren_info').get().then((doc) {
      if (doc.exists) {
        pesantrenInfo = PesantrenInfo.fromJson(doc.data()!);
        notifyListeners();
      }
    });
  }

  void cancelSubscriptions() {
    santriSub?.cancel();
    musyrifSub?.cancel();
    halaqahSub?.cancel();
    kelasSub?.cancel();
    eventSub?.cancel();
    regSub?.cancel();
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
    final halaqahIds = halaqahList.where((h) => h.musyrifId == musyrifId).map((h) => h.id).toSet();
    return santriList.where((s) => halaqahIds.contains(s.halaqahId)).toList();
  }

  GraduationRegistration? getRegistration(String eventId, String santriId) {
    try { return graduationRegistrations.firstWhere((r) => r.eventId == eventId && r.santriId == santriId); } catch (_) { return null; }
  }
}
