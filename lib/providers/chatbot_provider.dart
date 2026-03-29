import 'package:flutter/material.dart';
import '../models/chatbot_model.dart';
import '../models/dish_model.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';

class ChatbotProvider with ChangeNotifier {
  final _db = DatabaseService();
  final _gemini = GeminiService();
  List<ChatBotModel> _entries = [];
  final List<Map<String, String>> _history = [];
  bool _isTyping = false;

  List<ChatBotModel> get entries => _entries;
  List<Map<String, String>> get history => _history;
  bool get isTyping => _isTyping;

  ChatbotProvider() {
    _db.getChatBotData().listen((list) {
      _entries = list;
      notifyListeners();
    });
  }

  void addMessage(String role, String content) {
    _history.add({'role': role, 'content': content});
    notifyListeners();
  }

  void resetHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Xử lý tin nhắn và trả lời tự động dựa trên FAQ + Menu
  Future<void> processMessage(String text, List<DishModel> dishes) async {
    addMessage('user', text);
    
    // Giả lập bot đang "suy nghĩ"
    await Future.delayed(const Duration(milliseconds: 800));

    final msg = text.toLowerCase();
    String response = '';

    // 1. Kiểm tra FAQ từ Firestore
    for (final entry in _entries) {
      if (msg.contains(entry.question.toLowerCase())) {
        response = entry.answer;
        break;
      }
    }

    // 2. Nếu không khớp FAQ -> Dùng AI Gemini
    if (response.isEmpty) {
      _isTyping = true;
      notifyListeners();
      
      try {
        response = await _gemini.generateResponse(text, dishes);
      } catch (e) {
        response = 'Dạ, tôi đang bận một chút, bạn thử lại sau nhé!';
      }
      
      _isTyping = false;
    }

    addMessage('bot', response);
  }

  // Admin methods (keeping existing)
  Future<void> addEntry(ChatBotModel entry) async => await _db.saveChatBotEntry(entry);
  Future<void> updateEntry(ChatBotModel entry) async => await _db.saveChatBotEntry(entry);
  Future<void> deleteEntry(String id) async => await _db.deleteChatBotEntry(id);
}
