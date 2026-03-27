// Model bàn ăn – Firestore collection: 'tables'
enum TableStatus { available, occupied, reserved }

class TableModel {
  final String id;          // table_1 ... table_20
  final String name;        // Bàn 1 ... Bàn 20
  final TableStatus status;
  final int capacity;       // số chỗ ngồi (2-6)

  const TableModel({
    required this.id,
    required this.name,
    this.status = TableStatus.available,
    this.capacity = 4,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'status': status.name,
    'capacity': capacity,
  };

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      capacity: map['capacity'] ?? 4,
    );
  }

  TableModel copyWith({String? name, TableStatus? status, int? capacity}) {
    return TableModel(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
    );
  }
}
