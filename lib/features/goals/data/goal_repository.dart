import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/goal_model.dart';

class GoalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GoalRepository(this._firestore, this._auth);

  String get _uid => _auth.currentUser!.uid;

  Stream<List<GoalModel>> watchGoals() {
    return _firestore
        .collection('goals')
        .where('uid', isEqualTo: _uid)
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
    await _firestore.collection('goals').doc(goalId).update({
      'currentAmount': FieldValue.increment(amount),
    });
  }

  Future<void> markCompleted(String goalId) async {
    await _firestore.collection('goals').doc(goalId).update({
      'status': GoalStatus.completed.name,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _firestore.collection('goals').doc(id).delete();
  }
}
