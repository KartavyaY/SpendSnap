import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CategoryRepository(this._firestore, this._auth);

  String get _uid => _auth.currentUser!.uid;

  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection('categories')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final snap = await _firestore
        .collection('categories')
        .where('uid', isEqualTo: _uid)
        .get();
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toFirestore());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  Future<void> updateBudgetLimit(String categoryId, double? limit) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'monthlyLimit': limit,
    });
  }
}
