import 'package:flutter_dotenv/flutter_dotenv.dart';

// Các hằng số cấu hình toàn cục
class AppConstants {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
