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

  const CategoryModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.icon,
    required this.color,
    this.monthlyLimit,
    this.isDefault = false,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      uid: data['uid'] as String,
      name: data['name'] as String,
      icon: data['icon'] as String? ?? 'other',
      color: data['color'] as String? ?? '#888780',
      monthlyLimit: (data['monthlyLimit'] as num?)?.toDouble(),
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'icon': icon,
        'color': color,
        'monthlyLimit': monthlyLimit,
        'isDefault': isDefault,
      };

  CategoryModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? icon,
    String? color,
    double? monthlyLimit,
    bool? isDefault,
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
      );

  @override
  List<Object?> get props =>
      [id, uid, name, icon, color, monthlyLimit, isDefault];
}

const defaultCategories = [
  {'name': 'Food', 'icon': 'food', 'color': '#D85A30'},
  {'name': 'Transport', 'icon': 'transport', 'color': '#378ADD'},
  {'name': 'Shopping', 'icon': 'shopping', 'color': '#D4537E'},
  {'name': 'Bills', 'icon': 'bills', 'color': '#BA7517'},
  {'name': 'Entertainment', 'icon': 'entertainment', 'color': '#7F77DD'},
  {'name': 'Health', 'icon': 'health', 'color': '#1D9E75'},
  {'name': 'Salary', 'icon': 'salary', 'color': '#639922'},
  {'name': 'Other', 'icon': 'other', 'color': '#888780'},
];
