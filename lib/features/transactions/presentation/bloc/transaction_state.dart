import 'package:equatable/equatable.dart';
import '../../domain/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final List<TransactionModel> filtered;
  final TransactionType? typeFilter;
  final String? categoryFilter;
  final String? searchQuery;

  const TransactionLoaded({
    required this.transactions,
    required this.filtered,
    this.typeFilter,
    this.categoryFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props =>
      [transactions, filtered, typeFilter, categoryFilter, searchQuery];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}

class TransactionOperationSuccess extends TransactionState {
  final String message;
  const TransactionOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
