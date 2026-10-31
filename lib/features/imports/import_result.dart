class ImportRowError {
  const ImportRowError(this.row, this.message);
  final int row;
  final String message;
}

class ImportResult {
  const ImportResult({
    required this.total,
    required this.imported,
    required this.duplicates,
    required this.errors,
    this.jobId,
  });

  final String? jobId;
  final int total;
  final int imported;
  final int duplicates;
  final List<ImportRowError> errors;

  factory ImportResult.fromJson(Map<String, dynamic> j) => ImportResult(
        jobId: j['jobId'] as String?,
        total: (j['total'] as num?)?.toInt() ?? 0,
        imported: (j['imported'] as num?)?.toInt() ?? 0,
        duplicates: (j['duplicates'] as num?)?.toInt() ?? 0,
        errors: ((j['errors'] as List?) ?? const [])
            .map((e) => ImportRowError((e['row'] as num?)?.toInt() ?? 0, '${e['message']}'))
            .toList(),
      );
}
