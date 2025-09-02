class Supplier {
  final String id;
  final String shopId;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Supplier({
    required this.id,
    required this.shopId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      shopId: map['shop_id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      createdAt: DateTime.parse(map['created_at']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Supplier copyWith({
    String? id,
    String? shopId,
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Supplier(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Supplier{id: $id, name: $name, address: $address}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
