import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc(this._repository) : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoad);
    on<AddCategory>(_onAdd);
    on<UpdateCategory>(_onUpdate);
    on<DeleteCategory>(_onDelete);
    on<UpdateBudgetLimit>(_onUpdateLimit);
  }

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    await emit.forEach<List<CategoryModel>>(
      _repository.watchCategories(),
      onData: CategoryLoaded.new,
      onError: (err, _) => CategoryError(err.toString()),
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
}
