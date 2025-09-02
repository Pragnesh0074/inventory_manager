class Customer {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String? address;
  final String? email;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Customer({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.address,
    this.email,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      shopId: map['shop_id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      createdAt: DateTime.parse(map['created_at']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Customer copyWith({
    String? id,
    String? shopId,
    String? name,
    String? phone,
    String? address,
    String? email,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Customer(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phone: $phone}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
