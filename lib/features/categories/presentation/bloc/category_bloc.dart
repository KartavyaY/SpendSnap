import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/category_repository.dart';
import '../../domain/category_model.dart';
import 'category_event.dart';
import 'category_state.dart';

class _CatsUpdated extends CategoryEvent {
  final List<CategoryModel> cats;
  const _CatsUpdated(this.cats);
  @override
  List<Object?> get props => [cats];
}

class _CatStreamError extends CategoryEvent {
  final String message;
  const _CatStreamError(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;
  StreamSubscription<List<CategoryModel>>? _sub;

  CategoryBloc(this._repository) : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoad);
    on<_CatsUpdated>((e, emit) => emit(CategoryLoaded(e.cats)));
    on<_CatStreamError>((e, emit) => emit(CategoryError(e.message)));
    on<AddCategory>(_onAdd);
    on<UpdateCategory>(_onUpdate);
    on<DeleteCategory>(_onDelete);
    on<UpdateBudgetLimit>(_onUpdateLimit);
  }

  void _onLoad(LoadCategories event, Emitter<CategoryState> emit) {
    _sub?.cancel();
    emit(const CategoryLoading());
    _sub = _repository.watchCategories().listen(
      (cats) => add(_CatsUpdated(cats)),
      onError: (Object err, _) => add(_CatStreamError(err.toString())),
    );
  }

  Future<void> _onAdd(AddCategory event, Emitter<CategoryState> emit) async {
    try {
      await _repository.addCategory(event.category);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.updateCategory(event.category);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.deleteCategory(event.id);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onUpdateLimit(
    UpdateBudgetLimit event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.updateBudgetLimit(event.categoryId, event.limit);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
