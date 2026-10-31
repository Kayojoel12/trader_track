import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../core/theme.dart';

/// Espace réservé en bas du contenu pour que la barre flottante ne masque rien.
const double kNavInset = 110;

class _Tab {
  const _Tab(this.path, this.labelKey, this.icon);
  final String path;
  final String labelKey;
  final IconData icon;
}

const _tabs = [
  _Tab('/', 'nav.home', Icons.space_dashboard_outlined),
  _Tab('/journal', 'nav.journal', Icons.menu_book_outlined),
  _Tab('/analytics', 'nav.analytics', Icons.insights_outlined),
  _Tab('/risk', 'nav.risk', Icons.shield_outlined),
  _Tab('/markets', 'nav.markets', Icons.candlestick_chart_outlined),
  _Tab('/community', 'nav.community', Icons.groups_outlined),
  _Tab('/profile', 'nav.profile', Icons.person_outline),
];

/// Contenu plein écran + barre de navigation flottante, fixe en bas,
/// centrée et limitée à 520 px (mobile, tablette, ordinateur).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _tabs
        .indexWhere((t) => t.path == '/' ? loc == '/' : loc.startsWith(t.path));
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _FloatingNav(
                    selected: index,
                    onTap: (i) => context.go(_tabs[i].path),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: context.tr(_tabs[i].labelKey),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onTap(i),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: i == selected
                          ? AppColors.accent.withValues(alpha: 0.16)
                          : null,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_tabs[i].icon,
                            size: 20,
                            color: i == selected
                                ? AppColors.accent
                                : AppColors.muted),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(_tabs[i].labelKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: i == selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i == selected
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
