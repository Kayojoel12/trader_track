import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

/// Appelle l'API NestJS avec le jeton de session Supabase.
/// flutter run --dart-define=API_BASE_URL=https://ton-api.exemple.com
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  // 10.0.2.2 = machine hôte vue depuis l'émulateur Android.
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw ApiException(401, 'Session expirée, reconnecte-toi.');
    final res = await _http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
    dynamic decoded;
    try {
      decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300 && decoded is Map<String, dynamic>) return decoded;
    final m = decoded is Map ? decoded['message'] : null;
    final message = m is List ? m.join(', ') : (m?.toString() ?? 'Erreur ${res.statusCode}');
    throw ApiException(res.statusCode, message);
  }
}

final apiClientProvider = Provider((ref) => ApiClient());
