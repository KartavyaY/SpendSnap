import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String currency;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.currency,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
        uid: uid,
        email: map['email'] as String,
        displayName: map['displayName'] as String? ?? '',
        currency: map['currency'] as String? ?? 'INR',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'currency': currency,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? currency,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [uid, email, displayName, currency, createdAt];
}
