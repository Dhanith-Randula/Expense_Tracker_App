import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _expenseCollection {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseCollection.add(
      expense.toFirestore(),
    );
  }

  Stream<List<Expense>> getExpenses() {
    return _expenseCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => Expense.fromFirestore(document),
              )
              .toList(),
        );
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseCollection.doc(expense.id).update(
          expense.toFirestore(),
        );
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenseCollection.doc(expenseId).delete();
  }
}