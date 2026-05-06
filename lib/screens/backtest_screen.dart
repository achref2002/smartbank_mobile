import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BacktestScreen extends StatefulWidget {
  final String accountId;
  const BacktestScreen({super.key, required this.accountId});

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;
  int _testDays = 14;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.getBacktest(accountId: widget.accountId, testDays: _testDays);
      if (mounted) setState(() { _result = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(2);
    final p = s.split('.');
    final i = p[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v < 0 ? '-' : ''}$i.${p[1]}';
  }

  Color _metricColor(double prophetVal, double naiveVal, {bool lowerIsBetter = true}) {
    if (lowerIsBetter) {
      return prophetVal < naiveVal ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB);
    }
    return prophetVal > naiveVal ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2D),
        title: const Text('Model Accuracy Report',
            style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _run, tooltip: 'Re-run'),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildResult(),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Color(0xFFFFC700)),
      const SizedBox(height: 16),
      Text('Training Prophet on historical data\nand comparing to actual balances…',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF8B9AAD), fontSize: 13)),
    ]),
  );

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Color(0xFFFFB4AB), size: 48),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFFFB4AB), fontSize: 13)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _run, child: const Text('Retry')),
    ]),
  );

  Widget _buildResult() {
    final r = _result!;
    final prophet = Map<String, dynamic>.from(r['prophet'] as Map);
    final naive   = Map<String, dynamic>.from(r['naive_baseline'] as Map);
    final beatsNaive = r['beats_naive'] as bool;
    final verdict = r['verdict'] as String;
    final days = (r['days'] as List).cast<Map<String, dynamic>>();

    final prophetMae  = (prophet['mae']               as num).toDouble();
    final naiveMae    = (naive['mae']                  as num).toDouble();
    final prophetMape = (prophet['mape_pct']           as num).toDouble();
    final naiveMape   = (naive['mape_pct']             as num).toDouble();
    final prophetDir  = (prophet['direction_acc_pct']  as num).toDouble();
    final naiveDir    = (naive['direction_acc_pct']    as num).toDouble();
    final prophetCov  = prophet['ci_coverage_pct'] != null
        ? (prophet['ci_coverage_pct'] as num).toDouble() : null;
    final avgBal = (r['avg_balance'] as num).toDouble();

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Test window info ──
      _card(children: [
        Row(children: [
          const Icon(Icons.science_outlined, color: Color(0xFFFFC700), size: 16),
          const SizedBox(width: 8),
          Text('Backtest  ·  ${r['test_days']} day hold-out',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w600, color: Color(0xFF8B9AAD))),
          const Spacer(),
          _testDaysPicker(),
        ]),
        const SizedBox(height: 6),
        Text('Trained on ${r['train_days']} days  ·  tested ${r['test_period']['from']} → ${r['test_period']['to']}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF5A6B7F))),
        Text('Avg balance during test: ${_fmt(avgBal)} TND',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF5A6B7F))),
      ]),

      const SizedBox(height: 12),

      // ── Verdict banner ──
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: beatsNaive
              ? const Color(0xFF4CAF50).withOpacity(0.15)
              : const Color(0xFFFFB4AB).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: beatsNaive ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB),
              width: 1),
        ),
        child: Row(children: [
          Icon(beatsNaive ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: beatsNaive ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(verdict,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                  color: beatsNaive ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB)))),
        ]),
      ),

      const SizedBox(height: 12),

      // ── Metrics table ──
      _card(children: [
        const Text('METRICS', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
        const SizedBox(height: 12),
        _metricRow('Mean Absolute Error', '${_fmt(prophetMae)} TND', '${_fmt(naiveMae)} TND',
            _metricColor(prophetMae, naiveMae)),
        _metricRow('Error %  (MAPE)', '${prophetMape.toStringAsFixed(1)} %',
            '${naiveMape.toStringAsFixed(1)} %', _metricColor(prophetMape, naiveMape)),
        _metricRow('Direction accuracy', '${prophetDir.toStringAsFixed(1)} %',
            '${naiveDir.toStringAsFixed(1)} %', _metricColor(prophetDir, naiveDir, lowerIsBetter: false)),
        if (prophetCov != null)
          _metricRow('CI coverage (target 90 %)', '${prophetCov.toStringAsFixed(1)} %', '—',
              prophetCov >= 80 ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB)),
        const SizedBox(height: 8),
        const Text(
          'Naive baseline = assuming balance stays flat every day.\n'
          'Prophet must beat this to be worth using.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF3A5A7A)),
        ),
      ]),

      const SizedBox(height: 12),

      // ── What the metrics mean ──
      _card(children: [
        const Text('HOW TO READ THIS', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
        const SizedBox(height: 10),
        _explainRow('Mean Absolute Error',
            'Average TND difference between predicted and actual balance. '
            'Lower = more accurate. On a ${_fmt(avgBal)} TND average balance, '
            '${_fmt(prophetMae)} TND error is ${(prophetMae / avgBal.abs() * 100).toStringAsFixed(1)} % off.'),
        _explainRow('Error % (MAPE)',
            'Same error expressed as a percentage of the actual balance. '
            'Under 5 % is excellent. Over 20 % = unreliable.'),
        _explainRow('Direction accuracy',
            'Did the model correctly predict whether the balance went up or down? '
            '50 % = random guessing. Over 60 % = useful signal.'),
        _explainRow('CI coverage',
            'What fraction of actual values fell inside the predicted confidence band? '
            'Should be close to 90 % (the band width used). '
            'Far below 90 % = band is overconfident.'),
      ]),

      const SizedBox(height: 12),

      // ── Day-by-day comparison ──
      _card(children: [
        const Text('DAY-BY-DAY', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
        const SizedBox(height: 10),
        ...days.map((d) => _dayRow(d)),
      ]),
    ]);
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF162639),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _metricRow(String label, String prophetVal, String naiveVal, Color prophetColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFD3E3FF)))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(prophetVal, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w700, color: prophetColor)),
            Text('naive: $naiveVal',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF5A6B7F))),
          ]),
        ]),
      );

  Widget _explainRow(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
          fontWeight: FontWeight.w600, color: Color(0xFFFFC700))),
      const SizedBox(height: 3),
      Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF8B9AAD))),
    ]),
  );

  Widget _dayRow(Map<String, dynamic> d) {
    final actual  = (d['actual']        as num).toDouble();
    final prophet = (d['prophet_pred']  as num).toDouble();
    final pErr    = (d['prophet_error'] as num).toDouble();
    final inCi    = d['actual_in_ci'] as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 72,
            child: Text(d['date'] as String,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF8B9AAD)))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Actual: ${_fmt(actual)} TND',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white)),
          Text('Prophet: ${_fmt(prophet)} TND  (err ${_fmt(pErr)} TND)',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                  color: pErr < 200 ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB))),
        ])),
        Icon(inCi ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: inCi ? const Color(0xFF4CAF50) : const Color(0xFF5A6B7F)),
      ]),
    );
  }

  Widget _testDaysPicker() => DropdownButton<int>(
    value: _testDays,
    dropdownColor: const Color(0xFF162639),
    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFFFC700)),
    underline: const SizedBox(),
    items: [7, 14, 21, 30].map((v) => DropdownMenuItem(
      value: v,
      child: Text('$v days'),
    )).toList(),
    onChanged: (v) {
      if (v != null) { setState(() => _testDays = v); _run(); }
    },
  );
}
