import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shell/app_shell.dart';
import 'position_sizer.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final _balanceController = TextEditingController(text: '10000');
  final _riskPctController = TextEditingController(text: '1.0');
  final _stopPipsController = TextEditingController(text: '20');
  final _pipValueController = TextEditingController(text: '10');
  final _entryController = TextEditingController();
  final _slController = TextEditingController();
  final _tpController = TextEditingController();

  double _recommendedLot = 0.0;
  double _amountAtRisk = 0.0;
  double? _rrRatio;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _riskPctController.dispose();
    _stopPipsController.dispose();
    _pipValueController.dispose();
    _entryController.dispose();
    _slController.dispose();
    _tpController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim());

  void _calculate() {
    setState(() {
      _errorMsg = null;
      final balance = _parse(_balanceController) ?? 0;
      final pct = _parse(_riskPctController) ?? 0;
      final pipVal = _parse(_pipValueController) ?? 10;
      var stopPips = _parse(_stopPipsController) ?? 0;

      final entry = _parse(_entryController);
      final sl = _parse(_slController);
      final tp = _parse(_tpController);

      // Calcul auto de la distance en pips si les prix sont fournis
      if (entry != null && sl != null && entry > 0 && sl > 0) {
        final diff = (entry - sl).abs();
        // Estimation standard forex : 1 pip = 0.0001 (ou 0.01 pour JPY/indices)
        final pips = diff >= 1.0 ? diff : diff * 10000;
        stopPips = double.parse(pips.toStringAsFixed(1));
        _stopPipsController.text = stopPips.toString();
      }

      if (entry != null && sl != null && tp != null) {
        _rrRatio = PositionSizer.rr(entry: entry, sl: sl, tp: tp);
      } else {
        _rrRatio = null;
      }

      if (balance <= 0 || pct <= 0 || stopPips <= 0 || pipVal <= 0) {
        _recommendedLot = 0.0;
        _amountAtRisk = 0.0;
        return;
      }

      final riskAmount = PositionSizer.riskFromPercent(balance, pct);
      _amountAtRisk = riskAmount;

      try {
        _recommendedLot = PositionSizer.lotSize(
          riskAmount: riskAmount,
          stopPips: stopPips,
          pipValuePerLot: pipVal,
        );
      } catch (e) {
        _errorMsg = e.toString();
        _recommendedLot = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('risk.title')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, kNavInset + 20),
              children: [
                _buildResultHeader(context),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('risk.calculator'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: context.tr('risk.balance'),
                          controller: _balanceController,
                          suffix: '\$',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: context.tr('risk.percent'),
                                controller: _riskPctController,
                                suffix: '%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [0.5, 1.0, 1.5, 2.0].map((p) {
                            return ActionChip(
                              label: Text('$p%'),
                              onPressed: () {
                                _riskPctController.text = p.toString();
                                _calculate();
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: context.tr('risk.stopDistance'),
                                controller: _stopPipsController,
                                suffix: 'pips',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: context.tr('risk.pipValue'),
                                controller: _pipValueController,
                                suffix: '\$',
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Text(
                          'Calcul automatique par les prix (optionnel)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: context.tr('trade.entry'),
                                controller: _entryController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildField(
                                label: context.tr('trade.sl'),
                                controller: _slController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildField(
                                label: context.tr('trade.tp'),
                                controller: _tpController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(color: AppColors.loss, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                _buildDisclaimerCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            context.tr('risk.recommendedLot'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_recommendedLot.toStringAsFixed(2)} lot',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricBadge(
                label: context.tr('risk.amountAtRisk'),
                val: '\$${_amountAtRisk.toStringAsFixed(2)}',
                color: AppColors.loss,
              ),
              if (_rrRatio != null)
                _metricBadge(
                  label: context.tr('risk.rrRatio'),
                  val: '1 : ${_rrRatio!.toStringAsFixed(2)}',
                  color: AppColors.gain,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBadge({
    required String label,
    required String val,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _calculate(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Card(
      color: AppColors.surface.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('risk.rule'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
