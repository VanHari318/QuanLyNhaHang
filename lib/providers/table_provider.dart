import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../services/database_service.dart';

class TableProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<TableModel> _tables = [];

  List<TableModel> get tables => _tables;

  TableProvider() {
    _dbService.getTables().listen((tables) {
      _tables = tables;
      notifyListeners();
    });
  }

  Future<void> updateStatus(String tableId, TableStatus status) async {
    await _dbService.updateTableStatus(tableId, status);
  }
}
