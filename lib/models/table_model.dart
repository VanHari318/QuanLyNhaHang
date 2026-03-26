enum TableStatus {
  available,
  occupied,
  reserved,
}

class TableModel {
  final String id;
  final String number;
  final TableStatus status;

  TableModel({
    required this.id,
    required this.number,
    this.status = TableStatus.available,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'status': status.toString().split('.').last,
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] ?? '',
      number: map['number'] ?? '',
      status: TableStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TableStatus.available,
      ),
    );
  }
}
