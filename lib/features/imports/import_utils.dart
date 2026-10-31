const allowedExtensions = ['html', 'htm', 'csv', 'xlsx'];
const maxImportBytes = 10 * 1024 * 1024;

/// Nom sûr pour le stockage : lettres, chiffres, point, tiret, souligné ; 80 caractères au plus (fin conservée).
String sanitizeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (cleaned.isEmpty) return 'rapport';
  return cleaned.length > 80 ? cleaned.substring(cleaned.length - 80) : cleaned;
}

/// Décalages proposés : UTC-12 à UTC+14, par heure, en minutes.
final List<int> offsetChoices = [for (var h = -12; h <= 14; h++) h * 60];

String formatOffset(int minutes) {
  if (minutes == 0) return 'UTC';
  final sign = minutes > 0 ? '+' : '-';
  return 'UTC$sign${minutes.abs() ~/ 60}';
}
