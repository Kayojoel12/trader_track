import 'package:flutter_test/flutter_test.dart';
import 'package:trade_track/features/imports/import_result.dart';
import 'package:trade_track/features/imports/import_utils.dart';

void main() {
  test('nom de fichier nettoyé', () {
    expect(sanitizeFileName('Rapport été 2026 (1).html'), 'Rapport__t__2026__1_.html');
    expect(sanitizeFileName(''), 'rapport');
    final long = sanitizeFileName('${'a' * 200}.csv');
    expect(long.length, 80);
    expect(long.endsWith('.csv'), isTrue);
  });

  test('décalage UTC', () {
    expect(formatOffset(0), 'UTC');
    expect(formatOffset(120), 'UTC+2');
    expect(formatOffset(-300), 'UTC-5');
    expect(offsetChoices.first, -720);
    expect(offsetChoices.last, 840);
  });

  test('lecture de la réponse API', () {
    final r = ImportResult.fromJson({
      'jobId': 'j1',
      'total': 48,
      'imported': 45,
      'duplicates': 3,
      'errors': [
        {'row': 7, 'message': 'volume invalide'}
      ],
    });
    expect(r.total, 48);
    expect(r.imported, 45);
    expect(r.duplicates, 3);
    expect(r.errors.single.row, 7);
    expect(ImportResult.fromJson({}).errors, isEmpty);
  });
}
