import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
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
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(getIt())..add(const AuthCheckRequested());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(
          create: (_) =>
              TransactionBloc(getIt())..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (_) =>
              CategoryBloc(getIt())..add(const LoadCategories()),
        ),
        BlocProvider(
          create: (_) => BudgetBloc(getIt(), getIt()),
        ),
        BlocProvider(
          create: (_) => GoalBloc(getIt())..add(const LoadGoals()),
        ),
        BlocProvider(
          create: (_) => InsightBloc(getIt<InsightEngine>()),
        ),
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
