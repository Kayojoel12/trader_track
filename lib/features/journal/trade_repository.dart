import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trade.dart';

/// MVP : accès direct à Supabase.
/// TODO(offline) : ajouter un cache local Drift + file `sync_queue`
/// (écriture locale d'abord, synchronisation ensuite).
class TradeRepository {
  TradeRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  Future<List<Trade>> fetchAll() async {
    final rows = await _db
        .from('trades')
        .select()
        .isFilter('deleted_at', null)
        .order('opened_at', ascending: false);
    return rows.map<Trade>(Trade.fromJson).toList();
  }

  Future<void> upsert(Trade t) =>
      _db.from('trades').upsert({...t.toJson(), 'user_id': _uid});

  Future<void> softDelete(String id) => _db
      .from('trades')
      .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  /// Crée un compte manuel par défaut au premier trade.
  Future<String> ensureDefaultAccount() async {
    final existing = await _db.from('accounts').select('id').limit(1);
    if (existing.isNotEmpty) return existing.first['id'] as String;
    final created = await _db
        .from('accounts')
        .insert({'user_id': _uid, 'name': 'Compte manuel', 'type': 'live', 'platform': 'manual', 'currency': 'USD'})
        .select('id')
        .single();
    return created['id'] as String;
  }
}

final tradeRepositoryProvider =
    Provider((ref) => TradeRepository(Supabase.instance.client));

class TradesNotifier extends AsyncNotifier<List<Trade>> {
  @override
  Future<List<Trade>> build() => ref.read(tradeRepositoryProvider).fetchAll();

  Future<void> add(Trade t) async {
    await ref.read(tradeRepositoryProvider).upsert(t);
    state = AsyncData([t, ...?state.value]);
  }

  Future<void> remove(String id) async {
    await ref.read(tradeRepositoryProvider).softDelete(id);
    state = AsyncData([...?state.value]..removeWhere((t) => t.id == id));
  }
}

final tradesProvider =
    AsyncNotifierProvider<TradesNotifier, List<Trade>>(TradesNotifier.new);
