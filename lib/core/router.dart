import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/imports/import_screen.dart';
import '../features/journal/add_trade_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/placeholder/placeholder_screen.dart';
import '../features/risk/risk_screen.dart';
import '../shell/app_shell.dart';

// Ce widget permet d'écouter les changements d'état de Supabase (connexion/déconnexion)
// et de forcer GoRouter à rafraîchir ses redirections.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = Supabase.instance.client.auth;
  
  return GoRouter(
    initialLocation: '/',
    // Le routeur se rafraîchit dès que l'utilisateur se connecte ou se déconnecte
    refreshListenable: _AuthRefresh(auth.onAuthStateChange),
    
    redirect: (context, state) {
      // Vérifie si l'utilisateur a une session active
      final loggedIn = auth.currentSession != null;
      
      // Vérifie si on essaie d'accéder à la page de login
      final onLogin = state.matchedLocation == '/login';

      // Si non connecté et pas sur la page de login -> redirection vers login
      if (!loggedIn) {
        return onLogin ? null : '/login';
      }

      // Si connecté et sur la page de login -> redirection vers l'accueil
      if (onLogin) {
        return '/';
      }

      // Sinon, on laisse passer la navigation normale
      return null;
    },
    
    routes: [
      // Route publique
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      
      // Routes plein écran (hors du Shell)
      GoRoute(path: '/journal/new', builder: (_, __) => const AddTradeScreen()),
      GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
      
      // Routes avec la barre de navigation (Shell)
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/risk', builder: (_, __) => const RiskScreen()),
          GoRoute(
            path: '/markets', 
            builder: (_, __) => const PlaceholderScreen(titleKey: 'nav.markets'),
          ),
          GoRoute(
            path: '/community', 
            builder: (_, __) => const PlaceholderScreen(titleKey: 'nav.community'),
          ),
          GoRoute(
            path: '/profile', 
            builder: (_, __) => const PlaceholderScreen(titleKey: 'nav.profile'),
          ),
        ],
      ),
    ],
  );
});