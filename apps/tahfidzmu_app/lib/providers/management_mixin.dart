import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:core_models/core_models.dart';
import 'auth_mixin.dart';
import 'data_mixin.dart';

mixin ManagementMixin on ChangeNotifier, AuthMixin, DataMixin {
  Future<void> updatePesantrenInfo(PesantrenInfo info) async {
    pesantrenInfo = info;
    await getCollection('settings').doc('pesantren_info').set(info.toJson());
    notifyListeners();
  }

  Future<void> addMusyrif(
    MusyrifData m, {
    String? username,
    String? password,
  }) async {
    String? cloudPhotoUrl;
    if (m.photoPath != null &&
        m.photoPath!.isNotEmpty &&
        !m.photoPath!.startsWith('http')) {
      try {
        cloudPhotoUrl = await firebase.uploadPhoto(
          localPath: m.photoPath!,
          folder: 'musyrif_photos',
          fileName: m.id,
        );
      } catch (e) {
        debugPrint('Failed to upload musyrif photo: $e');
      }
    }
    final updatedM = m.copyWith(photoPath: cloudPhotoUrl ?? m.photoPath);
    await getCollection('musyrif').doc(m.id).set(updatedM.toJson());
    
    final userKey = (username?.isNotEmpty ?? false)
        ? normalizeLoginKey(username!)
        : (m.nip?.isNotEmpty ?? false ? digitsOnly(m.nip!) : m.id);
        
    await getCollection('user_mappings').doc(userKey).set({
      'linkedId': m.id,
      'role': 'musyrif',
      'defaultPassword': password ?? userKey,
    });
  }

  Future<void> updateMusyrifData(String id, MusyrifData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null &&
        finalPhotoPath.isNotEmpty &&
        !finalPhotoPath.startsWith('http')) {
      try {
        finalPhotoPath = await firebase.uploadPhoto(
          localPath: finalPhotoPath,
          folder: 'musyrif_photos',
          fileName: id,
        );
      } catch (e) {
        debugPrint('Failed to update musyrif photo: $e');
      }
    }
    await getCollection('musyrif')
        .doc(id)
        .set(
          updated.copyWith(photoPath: finalPhotoPath).toJson(),
          SetOptions(merge: true),
        );
  }

  Future<void> removeMusyrif(String id) async =>
      await getCollection('musyrif').doc(id).delete();

  Future<void> addPengawas(
    PengawasData p, {
    required String username,
    required String password,
  }) async {
    String? cloudPhotoUrl;
    if (p.photoPath != null &&
        p.photoPath!.isNotEmpty &&
        !p.photoPath!.startsWith('http')) {
      try {
        cloudPhotoUrl = await firebase.uploadPhoto(
          localPath: p.photoPath!,
          folder: 'pengawas_photos',
          fileName: p.id,
        );
      } catch (e) {
        debugPrint('Failed to upload pengawas photo: $e');
      }
    }
    final updatedP = p.copyWith(photoPath: cloudPhotoUrl ?? p.photoPath);
    await getCollection('pengawas').doc(p.id).set(updatedP.toJson());
    final userKey = normalizeLoginKey(username);
    await getCollection('user_mappings').doc(userKey).set({
      'linkedId': p.id,
      'role': 'pengawas',
      'defaultPassword': password.isNotEmpty ? password : userKey,
    });
  }

  Future<void> updatePengawasData(String id, PengawasData updated) async {
    String? finalPhotoPath = updated.photoPath;
    if (finalPhotoPath != null &&
        finalPhotoPath.isNotEmpty &&
        !finalPhotoPath.startsWith('http')) {
      try {
        finalPhotoPath = await firebase.uploadPhoto(
          localPath: finalPhotoPath,
          folder: 'pengawas_photos',
          fileName: id,
        );
      } catch (e) {
        debugPrint('Failed to update pengawas photo: $e');
      }
    }
    await getCollection('pengawas')
        .doc(id)
        .set(
          updated.copyWith(photoPath: finalPhotoPath).toJson(),
          SetOptions(merge: true),
        );
  }

  Future<void> removePengawas(String id, String username) async {
    await getCollection('pengawas').doc(id).delete();
    await getCollection('user_mappings').doc(username).delete();
  }

  Future<void> addSantri(
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
    String? tanggalLahir,
    List<int>? initialMemorizedJuz,
    String? username,
    String? password,
  }) async {
    final id = getCollection('santri').doc().id;
    String? cloudPhotoUrl;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http')) {
      try {
        cloudPhotoUrl = await firebase.uploadPhoto(
          localPath: photoPath,
          folder: 'santri_photos',
          fileName: id,
        );
      } catch (e) {
        debugPrint('Failed to upload santri photo: $e');
      }
    }
    final santri = Santri(
      id: id,
      name: name,
      nis: nis,
      email: email,
      jenisKelamin: jenisKelamin,
      kelas: kelas,
      halaqahId: halaqahId,
      namaOrangTua: namaOrangTua,
      namaAyah: namaAyah,
      namaIbu: namaIbu,
      nomorHpWali: nomorHpWali,
      targetHafalan: targetHafalan,
      photoPath: cloudPhotoUrl ?? photoPath,
      tanggalLahir: tanggalLahir,
      initialMemorizedJuz: initialMemorizedJuz ?? [],
    );
    await getCollection('santri').doc(id).set(santri.toJson());
    
    final userKey = (username?.isNotEmpty ?? false)
        ? normalizeLoginKey(username!)
        : (nis?.isNotEmpty ?? false ? digitsOnly(nis!) : id);
        
    await getCollection('user_mappings').doc(userKey).set({
      'linkedId': id,
      'role': 'orangTua',
      'defaultPassword': password ?? userKey,
    });
  }

  Future<void> updateMusyrifInfo(
    String name,
    String lembaga, {
    String jabatan = '',
    String nomorHp = '',
  }) async {
    if (linkedMusyrifId == null) return;
    final m = getMusyrifById(linkedMusyrifId)?.copyWith(
      nama: name,
      lembaga: lembaga,
      jabatan: jabatan,
      nomorHp: nomorHp,
    );
    if (m != null) await updateMusyrifData(linkedMusyrifId!, m);
  }

  Future<void> resetPasswordForLinkedId(
    String linkedId,
    String newPassword,
  ) async {
    try {
      final snap = await getCollection('user_mappings')
          .where('linkedId', isEqualTo: linkedId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final docId = snap.docs.first.id;
        await getCollection('user_mappings').doc(docId).update({
          'defaultPassword': newPassword,
          'mustResetAuth': true,
        });
      }
    } catch (e) {
      debugPrint("Error in resetPasswordForLinkedId: $e");
      rethrow;
    }
  }

  Future<void> updateSantriInfo(
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
    String? tanggalLahir,
    String? status,
    List<int>? initialMemorizedJuz,
  }) async {
    final doc = getCollection('santri').doc(santriId);
    final existing = await doc.get();
    if (!existing.exists) return;
    final s = Santri.fromJson(existing.data()!);
    String? finalPhotoPath = photoPath;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http')) {
      try {
        finalPhotoPath = await firebase.uploadPhoto(
          localPath: photoPath,
          folder: 'santri_photos',
          fileName: santriId,
        );
      } catch (e) {
        debugPrint('Failed to update santri photo: $e');
      }
    }
    await doc.update(
      s.copyWith(
            name: name,
            nis: nis,
            email: email,
            jenisKelamin: jenisKelamin,
            kelas: kelas,
            halaqahId: halaqahId,
            namaOrangTua: namaOrangTua,
            namaAyah: namaAyah,
            namaIbu: namaIbu,
            nomorHpWali: nomorHpWali,
            targetHafalan: targetHafalan,
            photoPath: finalPhotoPath,
            tanggalLahir: tanggalLahir,
            status: status,
            initialMemorizedJuz: initialMemorizedJuz,
          )
          .toJson(),
    );
  }

  Future<void> removeSantri(String santriId) async =>
      await getCollection('santri').doc(santriId).delete();

  Future<void> addHalaqah(HalaqahData h) async =>
      await getCollection('halaqah').doc(h.id).set(h.toJson());
  Future<void> updateHalaqah(String id, HalaqahData updated) async =>
      await getCollection('halaqah').doc(id).update(updated.toJson());
  Future<void> removeHalaqah(String id) async =>
      await getCollection('halaqah').doc(id).delete();
  Future<void> addKelas(KelasData k) async =>
      await getCollection('kelas').doc(k.id).set(k.toJson());
  Future<void> updateKelas(String id, KelasData updated) async =>
      await getCollection('kelas').doc(id).update(updated.toJson());
  Future<void> removeKelas(String id) async =>
      await getCollection('kelas').doc(id).delete();
  Future<void> addGraduationEvent(GraduationEvent event) async =>
      await getCollection('graduation_events').doc(event.id).set(event.toJson());
  Future<void> updateGraduationEvent(String id, GraduationEvent updated) async =>
      await getCollection('graduation_events').doc(id).update(updated.toJson());
  Future<void> removeGraduationEvent(String id) async =>
      await getCollection('graduation_events').doc(id).delete();
  Future<void> addGraduationRegistration(GraduationRegistration reg) async =>
      await getCollection('graduation_registrations').doc(reg.id).set(reg.toJson());
  Future<void> updateGraduationRegistration(String id, GraduationRegistration updated) async => 
      await getCollection('graduation_registrations').doc(id).update(updated.toJson());
  Future<void> removeGraduationRegistration(String id) async =>
      await getCollection('graduation_registrations').doc(id).delete();

  Future<void> updateAdminPhoto(String path) async {
    if (currentUserId == null) return;
    isPhotoUploading = true;
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'admin_photos', fileName: currentUserId!);
      await firebase.setUserData(currentUserId!, {'photoPath': cloudUrl});
      adminPhoto = cloudUrl; // Update local state in AuthMixin
    } catch (e) {
      debugPrint("Error updating admin photo: $e");
      rethrow;
    } finally {
      isPhotoUploading = false;
      notifyListeners();
    }
  }

  Future<void> updateMusyrifPhoto(String path) async {
    if (linkedMusyrifId == null) return;
    isPhotoUploading = true;
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'musyrif_photos', fileName: linkedMusyrifId!);
      await getCollection('musyrif').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Error updating musyrif photo: $e");
      rethrow;
    } finally {
      isPhotoUploading = false;
      notifyListeners();
    }
  }

  Future<void> updateSantriPhoto(String santriId, String path) async {
    isPhotoUploading = true;
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'santri_photos', fileName: santriId);
      await getCollection('santri').doc(santriId).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Error updating santri photo: $e");
      rethrow;
    } finally {
      isPhotoUploading = false;
      notifyListeners();
    }
  }

  Future<void> updatePengawasPhoto(String path) async {
    if (linkedMusyrifId == null) return;
    isPhotoUploading = true;
    notifyListeners();
    try {
      final cloudUrl = await firebase.uploadPhoto(localPath: path, folder: 'pengawas_photos', fileName: linkedMusyrifId!);
      await getCollection('pengawas').doc(linkedMusyrifId!).update({'photoPath': cloudUrl});
    } catch (e) {
      debugPrint("Error updating pengawas photo: $e");
      rethrow;
    } finally {
      isPhotoUploading = false;
      notifyListeners();
    }
  }

  Future<void> resetAllData() async {
    final collections = [
      'santri',
      'musyrif',
      'halaqah',
      'kelas',
      'graduation_events',
      'graduation_registrations',
      'user_mappings',
      'presensi',
      'active_sessions',
    ];
    
    for (var col in collections) {
      final snapshot = await getCollection(col).get();
      for (var doc in snapshot.docs) {
        if (col == 'santri') {
          final subCols = ['setoranHistory', 'tasmiHistory'];
          for (var sub in subCols) {
            final subSnap = await doc.reference.collection(sub).get();
            for (var subDoc in subSnap.docs) {
              await subDoc.reference.delete();
            }
          }
        }
        await doc.reference.delete();
      }
    }
    notifyListeners();
  }

  @override
  String normalizeLoginKey(String key) {
    return key.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D+'), '');
  }

  /// Temporary cleanup tool to remove experimental fields and fix missing metadata for collectionGroups
  Future<void> sanitizeFirestoreData() async {
    final pid = pesantrenId;
    if (pid == null) return;

    // 1. Sanitize Halaqah (Remove subjectId)
    final halaqahSnap = await firestore
        .collection('pesantren')
        .doc(pid)
        .collection('halaqah')
        .get();

    final batch = firestore.batch();
    for (var doc in halaqahSnap.docs) {
      if (doc.data().containsKey('subjectId')) {
        batch.update(doc.reference, {'subjectId': FieldValue.delete()});
      }
    }
    await batch.commit();

    // 2. Fix Setoran Metadata (Add pesantrenId/halaqahId if missing)
    // Note: This iterates through all santri. For 200+ it might need chunking.
    final santriSnap = await firestore
        .collection('pesantren')
        .doc(pid)
        .collection('santri')
        .get();

    for (var sDoc in santriSnap.docs) {
      final sData = sDoc.data();
      final hId = sData['halaqahId'] as String?;
      
      final historySnap = await sDoc.reference.collection('setoranHistory').get();
      if (historySnap.docs.isNotEmpty) {
        final hBatch = firestore.batch();
        for (var hDoc in historySnap.docs) {
          final hData = hDoc.data();
          if (!hData.containsKey('pesantrenId') || !hData.containsKey('halaqahId')) {
            hBatch.update(hDoc.reference, {
              'pesantrenId': pid,
              if (hId != null) 'halaqahId': hId,
            });
          }
        }
        await hBatch.commit();
      }
    }

    notifyListeners();
  }
}
