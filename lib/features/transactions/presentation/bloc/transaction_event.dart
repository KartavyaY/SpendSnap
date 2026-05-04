import 'package:equatable/equatable.dart';
import '../../domain/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  const LoadTransactions();
}

class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;
  const AddTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;
  const UpdateTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final String id;
  const DeleteTransaction(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterTransactions extends TransactionEvent {
  final TransactionType? typeFilter;
  final List<String> categoryFilters;
  final DateTime? from;
  final DateTime? to;
  final String? searchQuery;
  /// categoryId → category name, used for search matching.
  final Map<String, String>? categoryNames;

  const FilterTransactions({
    this.typeFilter,
    this.categoryFilters = const [],
    this.from,
    this.to,
    this.searchQuery,
    this.categoryNames,
  });

  @override
  List<Object?> get props =>
      [typeFilter, categoryFilters, from, to, searchQuery, categoryNames];
}
