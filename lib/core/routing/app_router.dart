import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/offline_banner.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/transactions/presentation/pages/transaction_list_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/budgets/presentation/pages/budget_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

class AppRouter {
  final AuthBloc authBloc;
  late final GoRouter router;

  AppRouter(this.authBloc) {
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: _AuthNotifier(authBloc),
      redirect: (context, state) {
        final isAuthed = authBloc.state is Authenticated;
        final isLoading = authBloc.state is AuthInitial;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == '/login' || loc == '/signup';

        if (isLoading) return null;
        if (!isAuthed && !isAuthRoute) return '/login';
        if (isAuthed && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignupPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionListPage(),
            ),
            GoRoute(
              path: '/transactions/add',
              builder: (_, __) => const AddTransactionPage(),
            ),
            GoRoute(
              path: '/transactions/edit/:id',
              builder: (_, state) => AddTransactionPage(
                editId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: '/categories',
              builder: (_, __) => const CategoriesPage(),
            ),
            GoRoute(
              path: '/budgets',
              builder: (_, __) => const BudgetPage(),
            ),
            GoRoute(
              path: '/goals',
              builder: (_, __) => const GoalsPage(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (_, __) => const AnalyticsPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    ('/', Icons.home_outlined, Icons.home, 'Home'),
    ('/transactions', Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions'),
    ('/analytics', Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics'),
    ('/goals', Icons.savings_outlined, Icons.savings, 'Goals'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = _tabs.indexWhere((t) =>
        t.$1 == '/' ? location == '/' : location.startsWith(t.$1));
    if (currentIndex < 0) currentIndex = 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.$2),
                  selectedIcon: Icon(t.$3),
                  label: t.$4,
                ))
            .toList(),
      ),
    ),
    );
  }
}
