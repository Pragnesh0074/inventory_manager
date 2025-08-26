class PurchaseParty {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final DateTime createdDate;
  DateTime lastUpdated;

  PurchaseParty({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.createdDate,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'createdDate': createdDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PurchaseParty.fromJson(Map<String, dynamic> json) {
    return PurchaseParty(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      createdDate: DateTime.parse(json['createdDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  @override
  String toString() {
    return name;
  }
}