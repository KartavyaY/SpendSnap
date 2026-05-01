import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/goal_model.dart';

class GoalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GoalRepository(this._firestore, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<GoalModel>> watchGoals() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _firestore
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GoalModel.fromFirestore).toList());
  }

  Future<void> addGoal(GoalModel goal) async {
    await _firestore
        .collection('goals')
        .doc(goal.id)
        .set(goal.toFirestore());
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _firestore
        .collection('goals')
        .doc(goal.id)
        .update(goal.toFirestore());
  }

  Future<void> contributeToGoal(String goalId, double amount) async {
    final ref = _firestore.collection('goals').doc(goalId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data()!;
      final target = (data['targetAmount'] as num).toDouble();
      final current = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;
      final remaining = (target - current).clamp(0.0, double.infinity);
      final capped = amount.clamp(0.0, remaining); // never exceed goal
      final newAmount = current + capped;

      final updates = <String, dynamic>{'currentAmount': newAmount};
      if (newAmount >= target) {
        updates['status'] = GoalStatus.completed.name;
      }
      txn.update(ref, updates);
    });
  }

  Future<void> markCompleted(String goalId) async {
    // Fetch current targetAmount so we can set currentAmount = targetAmount.
    final doc = await _firestore.collection('goals').doc(goalId).get();
    final target = (doc.data()?['targetAmount'] as num?)?.toDouble() ?? 0.0;
    await _firestore.collection('goals').doc(goalId).update({
      'status': GoalStatus.completed.name,
      'currentAmount': target, // force 100%
    });
  }

  Future<void> deleteGoal(String id) async {
    await _firestore.collection('goals').doc(id).delete();
  }
}
