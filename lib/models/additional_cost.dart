class AdditionalCost {
  final String id;
  final String name;
  final double amount;
  final String? description;

  AdditionalCost({
    required this.id,
    required this.name,
    required this.amount,
    this.description,
  });

  // Convert AdditionalCost to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
    };
  }

  // Create AdditionalCost from database Map
  factory AdditionalCost.fromMap(Map<String, dynamic> map) {
    return AdditionalCost(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
    );
  }

  // Convert AdditionalCost to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
    };
  }

  // Create AdditionalCost from JSON
  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      description: json['description'],
    );
  }

  // Create a copy of the additional cost with updated fields
  AdditionalCost copyWith({
    String? id,
    String? name,
    double? amount,
    String? description,
  }) {
    return AdditionalCost(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  // Helper method to get formatted amount
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'AdditionalCost{name: $name, amount: $amount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdditionalCost && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}