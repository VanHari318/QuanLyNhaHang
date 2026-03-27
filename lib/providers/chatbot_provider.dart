import 'package:flutter/material.dart';
import '../models/chatbot_model.dart';
import '../services/database_service.dart';

/// Provider quản lý dữ liệu FAQ chatbot
class ChatbotProvider with ChangeNotifier {
  final _db = DatabaseService();
  List<ChatBotModel> _entries = [];

  List<ChatBotModel> get entries => _entries;

  ChatbotProvider() {
    _db.getChatBotData().listen((list) {
      _entries = list;
      notifyListeners();
    });
  }

  Future<void> addEntry(ChatBotModel entry) async {
    await _db.saveChatBotEntry(entry);
  }

  Future<void> updateEntry(ChatBotModel entry) async {
    await _db.saveChatBotEntry(entry);
  }

  Future<void> deleteEntry(String id) async {
    await _db.deleteChatBotEntry(id);
  }
}
