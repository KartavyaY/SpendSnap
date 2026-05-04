import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/category_model.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddCategorySheet(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) return const LoadingIndicator();
            if (state is CategoryLoaded) {
              final expenseCats =
                  state.categories.where((c) => !c.isIncome).toList();
              final incomeCats =
                  state.categories.where((c) => c.isIncome).toList();

              return TabBarView(
                children: [
                  _CategoryGrid(
                    categories: expenseCats,
                    emptyTitle: 'No expense categories',
                    onTap: (cat) => _showEditCategorySheet(context, cat),
                  ),
                  _CategoryGrid(
                    categories: incomeCats,
                    emptyTitle: 'No income categories',
                    onTap: (cat) => _showEditCategorySheet(context, cat),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, {bool initialIsIncome = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: CategoryFormSheet(initialIsIncome: initialIsIncome),
        ),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: CategoryFormSheet(editing: cat),
        ),
      ),
    );
  }
}

// ── Category grid ─────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final String emptyTitle;
  final void Function(CategoryModel) onTap;

  const _CategoryGrid({
    required this.categories,
    required this.emptyTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        description: 'Add a category using the + button.',
        icon: Icons.category_outlined,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryCard(
        category: categories[i],
        onTap: () => onTap(categories[i]),
      ),
    );
  }
}

// ── Category card ──────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryIcon.resolve(category.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.monthlyLimit != null)
              Text(
                '₹${category.monthlyLimit!.toStringAsFixed(0)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Category form sheet ────────────────────────────────────────

class CategoryFormSheet extends StatefulWidget {
  final CategoryModel? editing;
  final bool initialIsIncome;
  const CategoryFormSheet({super.key, this.editing, this.initialIsIncome = false});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _selectedColor = '#0F6E56';
  String _selectedIcon = 'other';
  late bool _isIncome;

  static const _presetColors = [
    '#D85A30', '#378ADD', '#D4537E', '#BA7517',
    '#7F77DD', '#1D9E75', '#639922', '#888780',
    '#0F6E56', '#E24B4A', '#F0A500', '#6B4D9A',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _selectedIcon = widget.editing!.icon;
      _selectedColor = widget.editing!.color;
      _isIncome = widget.editing!.isIncome;
      if (widget.editing!.monthlyLimit != null) {
        _limitCtrl.text = widget.editing!.monthlyLimit!.toStringAsFixed(0);
      }
    } else {
      _isIncome = widget.initialIsIncome;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final name = _nameCtrl.text.trim();

    // Duplicate check: same name + same type, excluding self when editing.
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      final conflict = catState.categories.any((c) {
        if (widget.editing != null && c.id == widget.editing!.id) return false;
        return c.isIncome == _isIncome &&
            c.name.toLowerCase() == name.toLowerCase();
      });
      if (conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A ${_isIncome ? 'income' : 'expense'} category named "$name" already exists.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final limit = double.tryParse(_limitCtrl.text.trim());
    if (widget.editing != null) {
      context.read<CategoryBloc>().add(
            UpdateCategory(widget.editing!.copyWith(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              monthlyLimit: limit,
              isIncome: _isIncome,
              clearLimit: _limitCtrl.text.trim().isEmpty,
            )),
          );
    } else {
      final cat = CategoryModel(
        id: const Uuid().v4(),
        uid: authState.user.uid,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        monthlyLimit: limit,
        isIncome: _isIncome,
      );
      context.read<CategoryBloc>().add(AddCategory(cat));
    }
    Navigator.pop(context);
  }

  Color get _parsedColor {
    try {
      return Color(
          int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parsedColor;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: ListView(
          controller: scrollCtrl,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cream300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              widget.editing != null ? 'Edit Category' : 'New Category',
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 16),

            // Expense / Income toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 40,
                      decoration: BoxDecoration(
                        color: !_isIncome ? AppColors.ink : AppColors.cream200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: !_isIncome ? AppColors.paper : AppColors.stone600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isIncome ? AppColors.ink : AppColors.cream200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isIncome ? AppColors.paper : AppColors.stone600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 20),

            // Icon picker
            const Text('ICON', style: AppTypography.eyebrow),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: CategoryIcon.allKeys.length,
              itemBuilder: (_, i) {
                final key = CategoryIcon.allKeys[i];
                final selected = _selectedIcon == key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? color : AppColors.cream100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? color
                            : AppColors.borderHair,
                      ),
                    ),
                    child: Icon(
                      CategoryIcon.resolve(key),
                      size: 20,
                      color: selected ? Colors.white : AppColors.stone600,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Budget limit
            TextField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly budget (optional)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 20),

            // Color picker
            const Text('COLOR', style: AppTypography.eyebrow),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((hex) {
                final c =
                    Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: c.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                if (widget.editing != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context
                            .read<CategoryBloc>()
                            .add(DeleteCategory(widget.editing!.id));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.editing != null ? 'Update' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
