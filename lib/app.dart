import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/budgets/presentation/bloc/budget_bloc.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/categories/presentation/bloc/category_event.dart';
import 'features/goals/presentation/bloc/goal_bloc.dart';
import 'features/goals/presentation/bloc/goal_event.dart';
import 'features/insights/domain/insight_engine.dart';
import 'features/insights/presentation/bloc/insight_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';

class SpendSnapApp extends StatefulWidget {
  const SpendSnapApp({super.key});

  @override
  State<SpendSnapApp> createState() => _SpendSnapAppState();
}

class _SpendSnapAppState extends State<SpendSnapApp> {
  late final AuthBloc _authBloc;
  late final TransactionBloc _txnBloc;
  late final CategoryBloc _catBloc;
  late final GoalBloc _goalBloc;
  late final BudgetBloc _budgetBloc;
  late final InsightBloc _insightBloc;
  late final AppRouter _appRouter;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(getIt());
    _txnBloc = TransactionBloc(getIt())..add(const LoadTransactions());
    _catBloc = CategoryBloc(getIt())..add(const LoadCategories());
    _goalBloc = GoalBloc(getIt())..add(const LoadGoals());
    _budgetBloc = BudgetBloc(getIt(), getIt());
    _insightBloc = InsightBloc(getIt<InsightEngine>());
    _appRouter = AppRouter(_authBloc);

    // Re-trigger loads when auth completes (handles cold start where
    // currentUser becomes available after the initial bloc load).
    _authSub = _authBloc.stream.listen((state) {
      if (state is Authenticated) {
        _txnBloc.add(const LoadTransactions());
        _catBloc.add(const LoadCategories());
        _goalBloc.add(const LoadGoals());
      }
    });

    _authBloc.add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _authBloc.close();
    _txnBloc.close();
    _catBloc.close();
    _goalBloc.close();
    _budgetBloc.close();
    _insightBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _txnBloc),
        BlocProvider.value(value: _catBloc),
        BlocProvider.value(value: _budgetBloc),
        BlocProvider.value(value: _goalBloc),
        BlocProvider.value(value: _insightBloc),
      ],
      child: MaterialApp.router(
        title: 'SpendSnap',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
