import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tahfidz_app/models/pesantren_info.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Authentication ─────────────────────────────────────────────────────

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // ── User Data (Roles & Mapping) ────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 8));
      return doc.data();
    } catch (_) {
      try {
        final doc = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.cache));
        return doc.data();
      } catch (e) {
        debugPrint('Failed to get user data from cache: $e');
        return null;
      }
    }
  }

  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // ── Storage (Optimal Image Handling) ───────────────────────────────────

  /// Uploads a photo to Firebase Storage with automatic compression.
  /// Returns the public download URL.
  Future<String> uploadPhoto({
    required String localPath,
    required String folder,
    required String fileName,
  }) async {
    final File file = File(localPath);
    if (!await file.exists()) throw Exception("File not found");

    // 1. Compression (Optimal Blaze Plan usage)
    // Only compress if the file size is larger than 1MB to avoid slow pure-Dart processing.
    // Files picked via ImagePicker in this app are already resized and compressed natively.
    final int fileSize = await file.length();
    final File uploadFile;
    if (fileSize > 1024 * 1024) {
      uploadFile = await _compressImage(file);
    } else {
      uploadFile = file;
    }

    // 2. Upload
    final ref = _storage.ref().child(folder).child('$fileName.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'optimized': 'true'},
    );

    final uploadTask = await ref.putFile(uploadFile, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Cleanup temp file
    if (uploadFile.path != file.path) {
      try { await uploadFile.delete(); } catch (_) {}
    }

    return downloadUrl;
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    // Resize to max 800px width/height while maintaining aspect ratio
    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, 
        width: image.width > image.height ? 800 : null,
        height: image.height >= image.width ? 800 : null,
      );
    }

    // Compress quality to 80% (Professional standard)
    final compressedBytes = img.encodeJpg(image, quality: 80);
    
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    return await tempFile.writeAsBytes(compressedBytes);
  }

  // ── Generic CRUD Helpers ──────────────────────────────────────────────

  Stream<List<T>> streamCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> json) builder,
  }) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => builder(doc.data())).toList();
    });
  }

  Future<void> upsertDoc(String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteDoc(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  // ── Pesantren Info ─────────────────────────────────────────────────────

  Future<PesantrenInfo?> getPesantrenInfo() async {
    final doc = await _db.collection('settings').doc('pesantren_info').get();
    if (!doc.exists) return null;
    return PesantrenInfo.fromJson(doc.data()!);
  }

  Future<void> savePesantrenInfo(PesantrenInfo info) async {
    await _db.collection('settings').doc('pesantren_info').set(info.toJson());
  }

  // ── Modules ────────────────────────────────────────────────────────────

  Future<List<String>> getActiveModules() async {
    final doc = await _db.collection('settings').doc('modules').get();
    if (!doc.exists) return ['quran', 'hadits', 'tajwid', 'tahsin'];
    return List<String>.from(doc.data()?['active'] ?? []);
  }

  Future<void> saveActiveModules(List<String> modules) async {
    await _db.collection('settings').doc('modules').set({'active': modules});
  }
}
