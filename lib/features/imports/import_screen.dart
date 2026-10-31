import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../journal/trade_repository.dart';
import 'import_repository.dart';
import 'import_result.dart';
import 'import_utils.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _accountId;
  PlatformFile? _file;
  int _offset = 0;
  bool _busy = false;
  String? _error;
  ImportResult? _result;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (!mounted) return;

    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;

    String? error;

    if (f.bytes == null) {
      error = context.tr('import.noData');
    } else if (f.bytes!.length > maxImportBytes) {
      error = context.tr('import.tooBig');
    }

    if (!mounted) return;

    setState(() {
      _file = error == null ? f : null;
      _error = error;
      _result = null;
    });
  }

  Future<void> _run() async {
    final file = _file;
    final accountId = _accountId;

    if (file == null || accountId == null || file.bytes == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await ref.read(importRepositoryProvider).importFile(
            accountId: accountId,
            fileName: file.name,
            bytes: file.bytes!,
            offsetMinutes: _offset,
          );

      ref.invalidate(tradesProvider);

      if (mounted) {
        setState(() => _result = result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } on StorageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('import.title')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _note(
                  context.tr('import.readonly'),
                  AppColors.gain,
                  Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                accounts.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    '$e',
                    style: const TextStyle(color: AppColors.loss),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('import.noAccount')),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(importRepositoryProvider)
                                  .createMt5Account();

                              ref.invalidate(accountsProvider);
                            },
                            child: Text(context.tr('import.create')),
                          ),
                        ],
                      );
                    }

                    _accountId ??= list.first.id;

                    return DropdownButtonFormField<String>(
                      initialValue: _accountId,
                      decoration: InputDecoration(
                        labelText: context.tr('import.account'),
                      ),
                      items: [
                        for (final a in list)
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} · ${a.platform} · ${a.currency}',
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _accountId = v;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          context.tr('import.formats'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _busy ? null : _pick,
                          child: Text(context.tr('import.pick')),
                        ),
                        if (_file != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _file!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(_file!.size / 1024).toStringAsFixed(0)} Ko',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _offset,
                  decoration: InputDecoration(
                    labelText: context.tr('import.offset'),
                  ),
                  items: [
                    for (final m in offsetChoices)
                      DropdownMenuItem(
                        value: m,
                        child: Text(formatOffset(m)),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _offset = v ?? 0;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: Text(
                    context.tr('import.offsetHelp'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: (_busy || _file == null || _accountId == null)
                      ? null
                      : _run,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(context.tr('import.start')),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _note(
                    _error!,
                    AppColors.loss,
                    Icons.error_outline,
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _ResultCard(_result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(String text, Color color, IconData icon) => Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.r);

  final ImportResult r;

  Widget _stat(
    BuildContext c,
    String label,
    int value,
    Color color,
  ) =>
      Expanded(
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('import.done'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(
                  context,
                  context.tr('import.found'),
                  r.total,
                  AppColors.text,
                ),
                _stat(
                  context,
                  context.tr('import.imported'),
                  r.imported,
                  AppColors.gain,
                ),
                _stat(
                  context,
                  context.tr('import.duplicates'),
                  r.duplicates,
                  AppColors.muted,
                ),
                _stat(
                  context,
                  context.tr('import.errors'),
                  r.errors.length,
                  r.errors.isEmpty ? AppColors.muted : AppColors.loss,
                ),
              ],
            ),
            if (r.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final e in r.errors.take(5))
                Text(
                  'Ligne ${e.row} : ${e.message}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.loss,
                  ),
                ),
              if (r.errors.length > 5)
                Text(
                  '… +${r.errors.length - 5}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
