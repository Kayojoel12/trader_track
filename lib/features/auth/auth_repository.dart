import 'package:flutter/foundation.dart'; // Nécessaire pour kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._auth);
  
  final GoTrueClient _auth;

  // L'URL de redirection pour les applications mobiles (iOS/Android)
  static const String _redirectUrl = 'io.supabase.tradetrack://login-callback';

  /// Connexion avec email et mot de passe
  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Inscription avec email et mot de passe
  Future<void> signUp(String email, String password) =>
      _auth.signUp(email: email, password: password);

  /// Connexion via Google
  /// Sur le Web, redirectTo doit être null pour utiliser l'URL configurée dans Supabase.
  Future<void> signInWithGoogle() => _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _redirectUrl,
      );

  /// Connexion via Apple
  Future<void> signInWithApple() => _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : _redirectUrl,
      );

  /// Déconnexion
  Future<void> signOut() => _auth.signOut();

  // TODO(2FA): _auth.mfa.enroll / challenge / verify (TOTP) après la connexion.
}

/// Provider Riverpod pour injecter le repository dans l'application
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(Supabase.instance.client.auth),
);