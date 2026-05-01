import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class _TxnsUpdated extends TransactionEvent {
  final List<TransactionModel> txns;
  const _TxnsUpdated(this.txns);
  @override
  List<Object?> get props => [txns];
}

class _TxnStreamError extends TransactionEvent {
  final String message;
  const _TxnStreamError(this.message);
  @override
  List<Object?> get props => [message];
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;
  StreamSubscription<List<TransactionModel>>? _sub;
  List<TransactionModel> _all = [];

  TransactionBloc(this._repository) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<_TxnsUpdated>(_onUpdated);
    on<_TxnStreamError>((e, emit) => emit(TransactionError(e.message)));
    on<AddTransaction>(_onAdd);
    on<UpdateTransaction>(_onUpdate);
    on<DeleteTransaction>(_onDelete);
    on<FilterTransactions>(_onFilter);
  }

  void _onLoad(LoadTransactions event, Emitter<TransactionState> emit) {
    _sub?.cancel();
    emit(const TransactionLoading());
    _sub = _repository.watchTransactions().listen(
      (txns) => add(_TxnsUpdated(txns)),
      onError: (Object err, _) => add(_TxnStreamError(err.toString())),
    );
  }

  void _onUpdated(_TxnsUpdated event, Emitter<TransactionState> emit) {
    _all = event.txns;
    emit(TransactionLoaded(transactions: _all, filtered: _all));
  }

  Future<void> _onAdd(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.addTransaction(event.transaction);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.updateTransaction(event.transaction);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.deleteTransaction(event.id);
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  void _onFilter(FilterTransactions event, Emitter<TransactionState> emit) {
    var filtered = List<TransactionModel>.from(_all);

    if (event.typeFilter != null) {
      filtered =
          filtered.where((t) => t.type == event.typeFilter).toList();
    }

    if (event.categoryFilter != null && event.categoryFilter!.isNotEmpty) {
      filtered =
          filtered.where((t) => t.categoryId == event.categoryFilter).toList();
    }

    if (event.from != null) {
      filtered =
          filtered.where((t) => t.date.isAfter(event.from!)).toList();
    }

    if (event.to != null) {
      filtered =
          filtered.where((t) => t.date.isBefore(event.to!)).toList();
    }

    if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
      final query = event.searchQuery!.toLowerCase();
      filtered = filtered
          .where((t) => t.note?.toLowerCase().contains(query) ?? false)
          .toList();
    }

    emit(TransactionLoaded(
      transactions: _all,
      filtered: filtered,
      typeFilter: event.typeFilter,
      categoryFilter: event.categoryFilter,
      searchQuery: event.searchQuery,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
