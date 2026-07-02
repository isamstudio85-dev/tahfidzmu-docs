import 'dart:io';
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
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
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
    final compressedFile = await _compressImage(file);

    // 2. Upload
    final ref = _storage.ref().child(folder).child('$fileName.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'optimized': 'true'},
    );

    final uploadTask = await ref.putFile(compressedFile, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Cleanup temp file
    if (compressedFile.path != file.path) {
      try { await compressedFile.delete(); } catch (_) {}
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
