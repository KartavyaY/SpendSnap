import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRepository(this._firestore, this._auth);

  String get _uid => _auth.currentUser!.uid;

  Stream<List<TransactionModel>> watchTransactions() {
    return _firestore
        .collection('transactions')
        .where('uid', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(TransactionModel.fromFirestore).toList());
  }

  Future<List<TransactionModel>> fetchTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .where('uid', isEqualTo: _uid)
        .orderBy('date', descending: true);

    if (from != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }

    final snap = await query.get();
    return snap.docs.map(TransactionModel.fromFirestore).toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toFirestore());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }
}
