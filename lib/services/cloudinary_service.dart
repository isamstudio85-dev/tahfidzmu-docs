import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'diqumrva2';
  static const String _uploadPreset = 'tahfidzmu_upload';

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.isNotEmpty ? fileName : 'upload.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unggah foto gagal: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary tidak mengembalikan URL foto.');
    }

    return secureUrl;
  }

  Future<String> uploadImageFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadImage(
      bytes: bytes,
      fileName: file.name.isNotEmpty ? file.name : 'upload.jpg',
    );
  }
}
