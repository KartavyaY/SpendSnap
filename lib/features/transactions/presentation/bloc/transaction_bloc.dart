import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;
  List<TransactionModel> _all = [];

  TransactionBloc(this._repository) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<UpdateTransaction>(_onUpdate);
    on<DeleteTransaction>(_onDelete);
    on<FilterTransactions>(_onFilter);
  }

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    await emit.forEach<List<TransactionModel>>(
      _repository.watchTransactions(),
      onData: (txns) {
        _all = txns;
        return TransactionLoaded(transactions: txns, filtered: txns);
      },
      onError: (err, _) => TransactionError(err.toString()),
    );
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

  void _onFilter(
    FilterTransactions event,
    Emitter<TransactionState> emit,
  ) {
    var filtered = List<TransactionModel>.from(_all);

    if (event.typeFilter != null) {
      filtered = filtered
          .where((t) => t.type == event.typeFilter)
          .toList();
    }

    if (event.categoryFilter != null && event.categoryFilter!.isNotEmpty) {
      filtered = filtered
          .where((t) => t.categoryId == event.categoryFilter)
          .toList();
    }

    if (event.from != null) {
      filtered =
          filtered.where((t) => t.date.isAfter(event.from!)).toList();
    }

    if (event.to != null) {
      filtered = filtered.where((t) => t.date.isBefore(event.to!)).toList();
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
}
