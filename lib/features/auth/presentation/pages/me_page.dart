import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(title: Text('Me', style: AppTypography.headingLarge)),
          body: ListView(
            children: [
              // ── Header ──────────────────────────────────────
              _ProfileHeader(
                name: user?.displayName ?? '',
                email: user?.email ?? '',
              ),

              // ── Account ──────────────────────────────────────
              const _SectionLabel('Account'),
              _InfoRow(label: 'Name', value: user?.displayName ?? '—'),
              _InfoRow(label: 'Email', value: user?.email ?? '—'),
              _InfoRow(
                label: 'Member since',
                value: user != null ? _formatJoined(user.createdAt) : '—',
              ),

              // ── Preferences ──────────────────────────────────
              const _SectionLabel('Preferences'),
              _PreferenceRow(
                icon: Icons.currency_rupee_outlined,
                label: 'Currency',
                value: user?.currency ?? 'INR',
                comingSoon: true,
              ),
              const _PreferenceRow(
                icon: Icons.language_outlined,
                label: 'Language',
                value: 'English',
                comingSoon: true,
              ),

              // ── Sign out ─────────────────────────────────────
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const LogoutRequested()),
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  static String _formatJoined(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Profile header ─────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileHeader({required this.name, required this.email});

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (name.isNotEmpty)
            Text(
              name,
              style: AppTypography.headingLarge,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.stone500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(text.toUpperCase(), style: AppTypography.eyebrow),
    );
  }
}

// ── Info row (read-only) ───────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderHair)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.stone500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preference row (tappable) ──────────────────────────────

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool comingSoon;

  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: comingSoon
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderHair)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.stone600),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.bodyMedium),
            const Spacer(),
            if (comingSoon)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cream300,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'soon',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.stone600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else ...[
              Text(
                value,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.stone500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.stone500),
            ],
          ],
        ),
      ),
    );
  }
}
