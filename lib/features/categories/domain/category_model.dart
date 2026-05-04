import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String uid;
  final String name;
  final String icon;
  final String color;
  final double? monthlyLimit;
  final bool isDefault;
  final bool isIncome;

  const CategoryModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.icon,
    required this.color,
    this.monthlyLimit,
    this.isDefault = false,
    this.isIncome = false,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final icon = data['icon'] as String? ?? 'other';
    // Legacy fallback: pre-isIncome seed docs had no field. Treat 'salary' icon
    // as income so existing accounts don't need a re-seed.
    final isIncome = data['isIncome'] as bool? ?? (icon == 'salary');
    return CategoryModel(
      id: doc.id,
      uid: data['uid'] as String,
      name: data['name'] as String,
      icon: icon,
      color: data['color'] as String? ?? '#888780',
      monthlyLimit: (data['monthlyLimit'] as num?)?.toDouble(),
      isDefault: data['isDefault'] as bool? ?? false,
      isIncome: isIncome,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'icon': icon,
        'color': color,
        'monthlyLimit': monthlyLimit,
        'isDefault': isDefault,
        'isIncome': isIncome,
      };

  CategoryModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? icon,
    String? color,
    double? monthlyLimit,
    bool? isDefault,
    bool? isIncome,
    bool clearLimit = false,
  }) =>
      CategoryModel(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        monthlyLimit: clearLimit ? null : monthlyLimit ?? this.monthlyLimit,
        isDefault: isDefault ?? this.isDefault,
        isIncome: isIncome ?? this.isIncome,
      );

  @override
  List<Object?> get props =>
      [id, uid, name, icon, color, monthlyLimit, isDefault, isIncome];
}

const defaultCategories = [
  {'name': 'Food', 'icon': 'food', 'color': '#D85A30', 'isIncome': false},
  {'name': 'Transport', 'icon': 'transport', 'color': '#378ADD', 'isIncome': false},
  {'name': 'Shopping', 'icon': 'shopping', 'color': '#D4537E', 'isIncome': false},
  {'name': 'Bills', 'icon': 'bills', 'color': '#BA7517', 'isIncome': false},
  {'name': 'Entertainment', 'icon': 'entertainment', 'color': '#7F77DD', 'isIncome': false},
  {'name': 'Health', 'icon': 'health', 'color': '#1D9E75', 'isIncome': false},
  {'name': 'Rent', 'icon': 'rent', 'color': '#5B7FA6', 'isIncome': false},
  {'name': 'Salary', 'icon': 'salary', 'color': '#639922', 'isIncome': true},
  {'name': 'Other', 'icon': 'other', 'color': '#888780', 'isIncome': false},
];
