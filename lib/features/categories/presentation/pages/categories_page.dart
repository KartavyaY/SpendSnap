import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategorySheet(context),
          ),
        ],
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) return const LoadingIndicator();
          if (state is CategoryLoaded) {
            if (state.categories.isEmpty) {
              return const EmptyState(
                title: 'No categories',
                description: 'Add your first category to organize transactions.',
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
              itemCount: state.categories.length,
              itemBuilder: (_, i) {
                final cat = state.categories[i];
                return _CategoryCard(
                  category: cat,
                  onTap: () => _showEditCategorySheet(context, cat),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const _CategoryFormSheet(),
        ),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: _CategoryFormSheet(editing: cat),
        ),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 28)),
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

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? editing;
  const _CategoryFormSheet({this.editing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _selectedColor = '#0F6E56';

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
      _iconCtrl.text = widget.editing!.icon;
      _selectedColor = widget.editing!.color;
      if (widget.editing!.monthlyLimit != null) {
        _limitCtrl.text = widget.editing!.monthlyLimit!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final limit = double.tryParse(_limitCtrl.text.trim());
    if (widget.editing != null) {
      context.read<CategoryBloc>().add(
            UpdateCategory(widget.editing!.copyWith(
              name: _nameCtrl.text.trim(),
              icon: _iconCtrl.text.trim().isEmpty ? '📦' : _iconCtrl.text.trim(),
              color: _selectedColor,
              monthlyLimit: limit,
              clearLimit: _limitCtrl.text.trim().isEmpty,
            )),
          );
    } else {
      final cat = CategoryModel(
        id: const Uuid().v4(),
        uid: authState.user.uid,
        name: _nameCtrl.text.trim(),
        icon: _iconCtrl.text.trim().isEmpty ? '📦' : _iconCtrl.text.trim(),
        color: _selectedColor,
        monthlyLimit: limit,
      );
      context.read<CategoryBloc>().add(AddCategory(cat));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.editing != null ? 'Edit Category' : 'New Category',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _iconCtrl,
            decoration:
                const InputDecoration(labelText: 'Icon (emoji)', hintText: '🍔'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _limitCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly budget (optional)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 16),

          Text('Color', style: AppTypography.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors.map((hex) {
              final color =
                  Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
              final selected = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (widget.editing != null && !widget.editing!.isDefault)
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
              if (widget.editing != null && !widget.editing!.isDefault)
                const SizedBox(width: 12),
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
    );
  }
}
