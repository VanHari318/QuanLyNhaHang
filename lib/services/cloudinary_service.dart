import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  static const String _cloudName = 'dojcgjli4';
  
  // Specific settings for Staff Avatar
  static const String avatarPreset = 'AvartarNhanVien';
  static const String avatarFolder = 'AvartarNV';

  // Specific settings for Food Images
  static const String foodPreset = 'FoodPresents';
  static const String foodFolder = 'Food';

  static Future<String> uploadImage({
    File? imageFile,
    XFile? webImage,
    required String preset,
    required String folder,
  }) async {
    if (imageFile == null && webImage == null) return '';

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url);
      
      request.fields['upload_preset'] = preset;
      // Tránh lỗi khi Upload Preset (Unsigned) không cho phép ghi đè thư mục
      // request.fields['folder'] = folder;

      if (kIsWeb) {
        if (webImage != null) {
          final bytes = await webImage.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'upload.jpg',
          ));
        }
      } else {
        if (imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
        }
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = jsonDecode(responseString);

      if (response.statusCode != 200) {
        print('Cloudinary API Error: ${response.statusCode} - $responseString');
        return '';
      }

      return jsonData['secure_url'] ?? '';
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      return '';
    }
  }
}
