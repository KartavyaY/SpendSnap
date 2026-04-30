import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum GoalStatus { active, completed, abandoned }

class GoalModel extends Equatable {
  final String id;
  final String uid;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalStatus status;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.status,
    required this.createdAt,
  });

  double get progress => targetAmount > 0
      ? (currentAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  bool get isCompleted => status == GoalStatus.completed;

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      uid: data['uid'] as String,
      title: data['title'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      status: GoalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  GoalModel copyWith({
    String? id,
    String? uid,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalStatus? status,
    DateTime? createdAt,
  }) =>
      GoalModel(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, uid, title, targetAmount, currentAmount, deadline, status, createdAt];
}
