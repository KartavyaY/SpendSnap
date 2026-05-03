import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/offline_banner.dart';
import '../../core/theme/app_colors.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/transactions/domain/receipt_prefill.dart';
import '../../features/transactions/presentation/pages/transaction_list_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/budgets/presentation/pages/plan_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/auth/presentation/pages/me_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';

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
            GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
            GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionListPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, state) => AddTransactionPage(
                    prefill: state.extra is ReceiptPrefill
                        ? state.extra as ReceiptPrefill
                        : null,
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (_, state) => AddTransactionPage(
                    editId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
            GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
            GoRoute(
              path: '/budgets',
              builder: (_, state) {
                final tab = int.tryParse(
                        state.uri.queryParameters['tab'] ?? '0') ??
                    0;
                return PlanPage(initialTab: tab);
              },
            ),
            GoRoute(path: '/me', builder: (_, __) => const MePage()),
            GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsPage()),
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

  static const _tabRoutes = ['/', '/transactions', null, '/budgets', '/me'];

  int _currentIndex(String location) {
    for (int i = 0; i < _tabRoutes.length; i++) {
      if (i == 2) continue;
      final route = _tabRoutes[i]!;
      if (route == '/' ? location == '/' : location.startsWith(route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

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
        bottomNavigationBar: _SpendSnapTabBar(
          currentIndex: currentIndex,
          onTap: (i) {
            if (i == 2) {
              context.go('/scan');
            } else {
              context.go(_tabRoutes[i]!);
            }
          },
        ),
      ),
    );
  }
}

class _SpendSnapTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SpendSnapTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final barHeight =
        64.0 + (bottomPadding > 0 ? bottomPadding : 16.0);

    return SizedBox(
      height: barHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xEBFAF7F2),
              border: Border(
                top: BorderSide(color: AppColors.borderHair, width: 1),
              ),
            ),
            padding: EdgeInsets.only(
              top: 8,
              bottom: bottomPadding > 0 ? bottomPadding : 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TabItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _TabItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Activity',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                // Center snap button
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => onTap(2),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                _TabItem(
                  icon: Icons.pie_chart_outline_outlined,
                  label: 'Plan',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _TabItem(
                  icon: Icons.person_outline,
                  label: 'Me',
                  active: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.stone500;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
