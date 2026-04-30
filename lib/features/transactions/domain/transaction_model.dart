import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  final String id;
  final String uid;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String? note;
  final DateTime date;
  final bool isRecurring;
  final String? recurringFrequency;

  const TransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.date,
    this.isRecurring = false,
    this.recurringFrequency,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      uid: data['uid'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: data['categoryId'] as String,
      note: data['note'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringFrequency: data['recurringFrequency'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'categoryId': categoryId,
        'note': note,
        'date': Timestamp.fromDate(date),
        'isRecurring': isRecurring,
        'recurringFrequency': recurringFrequency,
      };

  TransactionModel copyWith({
    String? id,
    String? uid,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? note,
    DateTime? date,
    bool? isRecurring,
    String? recurringFrequency,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        date: date ?? this.date,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      );

  @override
  List<Object?> get props =>
      [id, uid, amount, type, categoryId, note, date, isRecurring];
}
