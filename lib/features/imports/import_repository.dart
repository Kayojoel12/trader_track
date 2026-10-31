import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_client.dart';
import 'import_result.dart';
import 'import_utils.dart';

class TradingAccount {
  const TradingAccount({required this.id, required this.name, required this.platform, required this.currency});
  final String id;
  final String name;
  final String platform;
  final String currency;

  factory TradingAccount.fromJson(Map<String, dynamic> j) => TradingAccount(
        id: j['id'] as String,
        name: j['name'] as String,
        platform: (j['platform'] as String?) ?? 'manual',
        currency: (j['currency'] as String?) ?? 'USD',
      );
}

class ImportRepository {
  ImportRepository(this._db, this._api);
  final SupabaseClient _db;
  final ApiClient _api;

  Future<List<TradingAccount>> accounts() async {
    final rows = await _db.from('accounts').select('id,name,platform,currency').order('created_at');
    return rows.map<TradingAccount>(TradingAccount.fromJson).toList();
  }

  Future<void> createMt5Account() => _db.from('accounts').insert({
        'user_id': _db.auth.currentUser!.id,
        'name': 'MT5',
        'type': 'live',
        'platform': 'mt5',
        'currency': 'USD',
      });

  /// 1) dépose le fichier dans le bucket privé `imports/<userId>/...`, 2) demande à l'API de l'importer.
  Future<ImportResult> importFile({
    required String accountId,
    required String fileName,
    required Uint8List bytes,
    required int offsetMinutes,
  }) async {
    final path = '${_db.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}_${sanitizeFileName(fileName)}';
    await _db.storage.from('imports').uploadBinary(path, bytes);
    final json = await _api.postJson('/imports', {
      'accountId': accountId,
      'filePath': path,
      'serverUtcOffsetMinutes': offsetMinutes,
    });
    return ImportResult.fromJson(json);
  }
}

final importRepositoryProvider =
    Provider((ref) => ImportRepository(Supabase.instance.client, ref.read(apiClientProvider)));

final accountsProvider = FutureProvider.autoDispose<List<TradingAccount>>(
    (ref) => ref.read(importRepositoryProvider).accounts());
