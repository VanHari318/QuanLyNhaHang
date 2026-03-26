enum UserRole {
  admin,
  waiter,
  chef,
  cashier,
  customer,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String imageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'imageUrl': imageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.customer,
      ),
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
