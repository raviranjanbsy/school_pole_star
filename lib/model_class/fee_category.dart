import 'package:equatable/equatable.dart';

class FeeCategory extends Equatable {
  final String id; // Unique ID from Firebase
  final String name; // e.g., "Tuition Fee", "Admission Fee"
  final String type; // "One-time", "Recurring"
  final String? frequency; // "Monthly", "Quarterly", "Yearly"
  final double amount;
  final bool isOptional;
  final String? description;

  const FeeCategory({
    required this.id,
    required this.name,
    required this.type,
    this.frequency,
    required this.amount,
    required this.isOptional,
    this.description,
  });

  factory FeeCategory.fromMap(Map<String, dynamic> map, String id) {
    return FeeCategory(
      id: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'One-time',
      frequency: map['frequency'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isOptional: map['isOptional'] as bool? ?? false,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'frequency': frequency,
      'amount': amount,
      'isOptional': isOptional,
      'description': description,
    };
  }

  FeeCategory copyWith({
    String? id,
    String? name,
    String? type,
    String? frequency,
    double? amount,
    bool? isOptional,
    String? description,
  }) {
    return FeeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      amount: amount ?? this.amount,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, type, frequency, amount, isOptional, description];
}
