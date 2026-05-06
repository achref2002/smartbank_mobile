import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/balance_models.dart';
import '../widgets/forecast_chart.dart';
import '../widgets/risk_card.dart';
import 'backtest_screen.dart';

class PredictionsScreen extends StatefulWidget {
  final String accountId;

  const PredictionsScreen({super.key, required this.accountId});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final _apiService = ApiService();

  List<Map<String, dynamic>> _linkedAccounts = [];
  String _selectedAccountId = '';

  // Per-account forecast cache so switching is instant
  final Map<String, BalancePredictionResponse?> _forecasts = {};
  final Map<String, bool> _generating = {};

  // Per-account recurring charges cache
  final Map<String, List<Map<String, dynamic>>> _recurringByAccount = {};

  bool _accountsLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadAccounts() async {
    setState(() { _accountsLoading = true; _error = null; });
    try {
      final resp = await _apiService.getMyAccounts();
      final accounts = (resp is List)
          ? resp.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _linkedAccounts = accounts;
          _accountsLoading = false;
          if (_selectedAccountId.isEmpty && accounts.isNotEmpty) {
            _selectedAccountId = accounts[0]['account_id']?.toString() ?? widget.accountId;
          }
        });
        if (_selectedAccountId.isNotEmpty) _loadForecast(_selectedAccountId);
      }
    } catch (e) {
      if (mounted) setState(() { _accountsLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadForecast(String accountId) async {
    if (_forecasts.containsKey(accountId)) return; // already loaded

    setState(() => _forecasts[accountId] = null);

    // Load forecast and recurring charges in parallel
    final results = await Future.wait([
      _apiService.getBalanceForecast(accountId: accountId).catchError((e) => null),
      _apiService.getRecurringCharges(accountId).catchError((_) => <dynamic>[]),
    ]);

    if (!mounted) return;

    final forecast = results[0] as BalancePredictionResponse?;
    final charges  = (results[1] as List? ?? [])
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();

    setState(() {
      _forecasts[accountId] = forecast;
      _recurringByAccount[accountId] = charges;
      if (forecast == null) {
        // don't show error for 404 — just show empty state + FAB
      }
    });
  }

  Future<void> _generateForecast(String accountId) async {
    setState(() {
      _generating[accountId] = true;
      _error = null;
    });
    try {
      final prediction = await _apiService.predictBalance(
        accountId: accountId,
        horizon: 30,
        salaryDay: 25,
      );
      if (mounted) {
        // Also (re)load recurring charges for this account
        _apiService.getRecurringCharges(accountId).then((r) {
          if (mounted) {
            setState(() => _recurringByAccount[accountId] =
                (r as List).map((c) => Map<String, dynamic>.from(c as Map)).toList());
          }
        }).catchError((_) {});

        setState(() {
          _forecasts[accountId] = prediction;
          _generating[accountId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Forecast generated successfully'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating[accountId] = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFFFB4AB),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _selectAccount(String id) {
    if (_selectedAccountId == id) return;
    setState(() { _selectedAccountId = id; _error = null; });
    // Remove cached forecast so _loadForecast re-fetches
    _forecasts.remove(id);
    _loadForecast(id);
  }

  bool get _isGenerating => _generating[_selectedAccountId] == true;
  BalancePredictionResponse? get _currentForecast => _forecasts[_selectedAccountId];

  /// For each forecast date, returns the recurring charges expected that day.
  /// Handles charges that repeat within the 7-day window (e.g. weekly cadence).
  Map<String, List<Map<String, dynamic>>> _chargesByDate(List<String> forecastDates) {
    final result = {for (final d in forecastDates) d: <Map<String, dynamic>>[]};
    final charges = _recurringByAccount[_selectedAccountId] ?? [];

    for (final charge in charges) {
      final nextStr = charge['next_expected_date'] as String?;
      final cadence = (charge['cadence_days'] as num?)?.toInt() ?? 30;
      if (nextStr == null) continue;
      try {
        var d = DateTime.parse(nextStr);
        final last = DateTime.parse(forecastDates.last);
        // Walk forward from next_expected_date, step by cadence, until past window
        while (!d.isAfter(last)) {
          final key =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (result.containsKey(key)) result[key]!.add(charge);
          d = d.add(Duration(days: cadence));
        }
      } catch (_) {}
    }
    return result;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2D),
        elevation: 0,
        title: const Text('Balance Forecast',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          if (_currentForecast != null && !_isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFFFC700)),
              tooltip: 'Retrain model',
              onPressed: () => _generateForecast(_selectedAccountId),
            ),
        ],
      ),
      body: _accountsLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC700)))
          : Column(
              children: [
                _buildAccountSelector(),
                Expanded(child: _buildBody()),
              ],
            ),
      floatingActionButton: (!_accountsLoading && _currentForecast == null && !_isGenerating && _selectedAccountId.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _generateForecast(_selectedAccountId),
              backgroundColor: const Color(0xFFFFC700),
              foregroundColor: const Color(0xFF0A1628),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Forecast', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildAccountSelector() {
    if (_linkedAccounts.isEmpty) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF0D1B2D),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACCOUNT', style: TextStyle(fontFamily: 'Inter', fontSize: 9,
              fontWeight: FontWeight.w700, color: Color(0xFF5A6B7F), letterSpacing: 1.2)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _linkedAccounts.map((acc) {
                final id = acc['account_id']?.toString() ?? '';
                final selected = _selectedAccountId == id;
                final hasForecast = _forecasts.containsKey(id) && _forecasts[id] != null;
                return GestureDetector(
                  onTap: () => _selectAccount(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFC700) : const Color(0xFF162639),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? const Color(0xFFFFC700) : const Color(0xFF1E3A5F)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(id,
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700,
                              color: selected ? const Color(0xFF0A1628) : const Color(0xFFA8C9F6),
                            )),
                        if (hasForecast) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF0A1628) : const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) return _buildTrainingState();

    // Forecast not yet loaded for this account (loading)
    if (!_forecasts.containsKey(_selectedAccountId)) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC700)));
    }

    final pred = _currentForecast;
    if (pred == null) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () => _generateForecast(_selectedAccountId),
      color: const Color(0xFFFFC700),
      backgroundColor: const Color(0xFF162639),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pred.isHistorical) _buildHistoricalBanner(pred),
          if (pred.isHistorical) const SizedBox(height: 12),
          if (!pred.isHighQuality) _buildQualityBanner(pred),
          if (!pred.isHighQuality) const SizedBox(height: 12),
          RiskCard(risk: pred.risk),
          const SizedBox(height: 16),
          _buildModelInfo(pred),
          const SizedBox(height: 16),
          _buildForecastChart(pred),
          const SizedBox(height: 16),
          _buildSevenDayBreakdown(pred),
          const SizedBox(height: 16),
          if (pred.risk.actions.isNotEmpty) _buildActionsCard(pred.risk.actions),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoricalBanner(BalancePredictionResponse pred) {
    final dataDate = pred.lastDataDate ?? pred.forecastStart ?? '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F00),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFC700).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFFFFC700), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HISTORICAL FORECAST',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.w700, color: Color(0xFFFFC700), letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  'Based on data up to $dataDate. Tap refresh to retrain when new transactions are available.',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                      color: Color(0xFFD4B800), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBanner(BalancePredictionResponse pred) {
    final quality = pred.forecastQuality ?? 'low';
    final isLow   = quality == 'low';
    final color   = isLow ? const Color(0xFFFFB4AB) : const Color(0xFFFFB74D);
    final bg      = isLow ? const Color(0xFF2D1010) : const Color(0xFF2A1A00);
    final label   = isLow ? 'LOW CONFIDENCE' : 'MEDIUM CONFIDENCE';
    final text    = isLow
        ? 'Limited transaction history or stale data. Add more transactions and retrain for better accuracy.'
        : 'Moderate data quality. Accuracy improves with more transaction history.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(isLow ? Icons.warning_amber : Icons.info_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(text,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                    color: color.withOpacity(0.85), height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTrainingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFC700)),
            const SizedBox(height: 24),
            const Text('Training AI Models…',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text('For $_selectedAccountId',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                    color: Color(0xFF8B9AAD))),
            const SizedBox(height: 4),
            const Text('This takes 10–120 seconds',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                    color: Color(0xFF5A6B7F))),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF162639),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  _TrainStep(label: 'Aggregating daily balance history', done: true),
                  _TrainStep(label: 'Training Prophet (trend + seasonality)', done: false),
                  _TrainStep(label: 'Training LSTM (non-linear patterns)', done: false),
                  _TrainStep(label: 'Combining ensemble + risk assessment', done: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                  color: const Color(0xFF162639),
                  borderRadius: BorderRadius.circular(48)),
              child: const Icon(Icons.timeline, size: 52, color: Color(0xFFFFC700)),
            ),
            const SizedBox(height: 24),
            Text('No Forecast for $_selectedAccountId',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 20,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Generate a 30-day AI-powered balance forecast.\nProphet captures trends; LSTM captures spending patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                  color: Color(0xFF8B9AAD), height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF2D1515),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                        color: Color(0xFFFFB4AB))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfo(BalancePredictionResponse pred) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFFFC700), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MODEL', style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(pred.modelType.toUpperCase(),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 22,
                        fontWeight: FontWeight.w800, color: Color(0xFFFFC700))),
                if (pred.generatedAt != null) ...[
                  const SizedBox(height: 4),
                  Text('Generated ${_friendlyDate(pred.generatedAt!)}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                          color: Color(0xFF5A6B7F))),
                ],
              ],
            ),
          ),
          _chip('${pred.dataPointsUsed}', 'data pts'),
          const SizedBox(width: 8),
          _chip('${pred.trainingSeconds.toStringAsFixed(1)}s', 'trained'),
          if (pred.mae != null) ...[
            const SizedBox(width: 8),
            _chip(pred.mae!.toStringAsFixed(0), 'MAE'),
          ],
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF213A59),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
              fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
              color: Color(0xFF8B9AAD))),
        ],
      ),
    );
  }

  Widget _buildForecastChart(BalancePredictionResponse pred) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF162639),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text('30-DAY BALANCE FORECAST',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
                if (pred.forecastStart != null) ...[
                  const Spacer(),
                  Text('${pred.forecastStart} → ${pred.forecastEnd}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
                          color: Color(0xFF5A6B7F))),
                ],
              ],
            ),
          ),
          ForecastChart(
            forecasts: pred.forecasts,
            currentBalance: pred.risk.currentBalance,
          ),
        ],
      ),
    );
  }

  Widget _buildSevenDayBreakdown(BalancePredictionResponse pred) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months   = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final days         = pred.forecasts.take(7).toList();
    final startBalance = pred.risk.currentBalance;
    final chargeMap    = _chargesByDate(days.map((f) => f.date).toList());

    // Thousand-separator formatter
    String _fmt(double v) {
      final abs = v.abs().toStringAsFixed(2);
      final parts = abs.split('.');
      final intPart = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return '${v < 0 ? '-' : ''}$intPart.${parts[1]}';
    }

    Color _balColor(double v) {
      if (v < 0)    return const Color(0xFFFFB4AB);
      if (v < 500)  return const Color(0xFFFF9800);
      if (v < 2000) return const Color(0xFFFFC700);
      return const Color(0xFF4CAF50);
    }

    String _deltaLabel(double delta, bool isFirst) {
      final abs = delta.abs().toStringAsFixed(0);
      final dir = delta >= 0 ? 'up' : 'down';
      return '${delta >= 0 ? '+' : '-'}$abs TND ${isFirst ? 'from today' : 'from yesterday'}';
    }

    // Confidence as a readable % — how tight is the range relative to predicted
    String _confidenceLabel(double lower, double upper, double predicted) {
      if (predicted == 0) return '';
      final pct = ((upper - lower) / predicted.abs() * 100).round();
      if (pct <= 5)  return 'Very confident';
      if (pct <= 15) return 'Fairly confident';
      if (pct <= 30) return 'Approximate';
      return 'Rough estimate';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR NEXT 7 DAYS',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                      fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                startBalance != 0
                    ? 'Starting from your current balance of ${_fmt(startBalance)} TND'
                    : 'Estimated end-of-day balances based on your spending history',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF5A6B7F)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          ...List.generate(days.length, (i) {
            final f        = days[i];
            final prev     = i == 0 ? startBalance : days[i - 1].predicted;
            final delta    = f.predicted - prev;
            final isUp     = delta >= 0;
            final dt       = DateTime.tryParse(f.date) ?? DateTime.now();
            final dayFull  = weekdays[dt.weekday - 1];
            final dateStr  = '${dt.day} ${months[dt.month - 1]}';
            final isWeekend = dt.weekday >= 6;
            final balColor = _balColor(f.predicted);
            final confLabel = _confidenceLabel(f.lower, f.upper, f.predicted);
            final dayCharges  = chargeMap[f.date] ?? [];
            final dayIncome   = dayCharges.where((c) => ((c['avg_amount'] as num?)?.toDouble() ?? 0) > 0).toList();
            final dayExpenses = dayCharges.where((c) => ((c['avg_amount'] as num?)?.toDouble() ?? 0) < 0).toList();
            final netKnown    = dayCharges.fold<double>(0, (s, c) => s + ((c['avg_amount'] as num?)?.toDouble() ?? 0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i > 0)
                  const Divider(color: Color(0xFF1E3A5F), height: 1, thickness: 1),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: day name + balance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day label
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              if (isWeekend)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC700).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('Weekend',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 8,
                                          fontWeight: FontWeight.w700, color: Color(0xFFFFC700))),
                                ),
                              Text(dayFull,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                                      fontWeight: FontWeight.w700, color: Colors.white)),
                            ]),
                            const SizedBox(height: 2),
                            Text(dateStr,
                                style: const TextStyle(fontFamily: 'Inter',
                                    fontSize: 12, color: Color(0xFF8B9AAD))),
                          ]),
                          const Spacer(),
                          // Balance
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${_fmt(f.predicted)} TND',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                                    fontWeight: FontWeight.w800, color: balColor)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(
                                isUp ? Icons.trending_up : Icons.trending_down,
                                size: 13,
                                color: isUp ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _deltaLabel(delta, i == 0),
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                    color: isUp ? const Color(0xFF4CAF50) : const Color(0xFFFFB4AB)),
                              ),
                            ]),
                          ]),
                        ],
                      ),

                      // Row 2: possible range + confidence
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.info_outline, size: 11, color: Color(0xFF3A5A7A)),
                        const SizedBox(width: 5),
                        Text(
                          'Could be between ${_fmt(f.lower)} and ${_fmt(f.upper)} TND  ·  $confLabel',
                          style: const TextStyle(fontFamily: 'Inter',
                              fontSize: 10, color: Color(0xFF3A5A7A)),
                        ),
                      ]),

                      // Row 3: why the balance changes
                      const SizedBox(height: 10),

                      // Income block
                      if (dayIncome.isNotEmpty) ...[
                        _buildChargeBlock(
                          label: 'Expected income',
                          charges: dayIncome,
                          accent: const Color(0xFF4CAF50),
                          bg: const Color(0xFF0A2010),
                          fmt: _fmt,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Expenses block
                      if (dayExpenses.isNotEmpty) ...[
                        _buildChargeBlock(
                          label: 'Expected payments',
                          charges: dayExpenses,
                          accent: const Color(0xFFFFB4AB),
                          bg: const Color(0xFF1A0D0D),
                          fmt: _fmt,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Net line when both are present
                      if (dayIncome.isNotEmpty && dayExpenses.isNotEmpty) ...[
                        Row(children: [
                          const SizedBox(width: 2),
                          Text(
                            'Net scheduled: ${netKnown >= 0 ? '+' : ''}${_fmt(netKnown)} TND',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: netKnown >= 0
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFB4AB),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                      ],

                      // No-transaction hint
                      if (dayCharges.isEmpty)
                        Row(children: [
                          const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF3A5A7A)),
                          const SizedBox(width: 5),
                          Text(
                            'AI estimate · no transactions scheduled for $dayFull',
                            style: const TextStyle(fontFamily: 'Inter',
                                fontSize: 10, color: Color(0xFF3A5A7A)),
                          ),
                        ]),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            );
          }),

          // Footer note
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF3A5A7A)),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Amounts are AI predictions based on your past 12 months of transactions. Actual results may vary.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF3A5A7A)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BacktestScreen(accountId: _selectedAccountId),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3A5A7A)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Model accuracy',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                          color: Color(0xFF3A5A7A))),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeBlock({
    required String label,
    required List<Map<String, dynamic>> charges,
    required Color accent,
    required Color bg,
    required String Function(double) fmt,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                fontWeight: FontWeight.w600, color: accent.withOpacity(0.8))),
        const SizedBox(height: 6),
        ...charges.map((c) {
          final amount = (c['avg_amount'] as num?)?.toDouble() ?? 0.0;
          final name   = c['merchant_name'] as String? ?? '—';
          final cat    = c['category'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 12, color: Color(0xFFD3E3FF)),
                    overflow: TextOverflow.ellipsis),
              ),
              if (cat.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(cat,
                    style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 9, color: Color(0xFF5A6B7F))),
              ],
              const SizedBox(width: 8),
              Text(
                '${amount >= 0 ? '+' : '-'}${fmt(amount.abs())} TND',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w700, color: accent),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildActionsCard(List<String> actions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFC700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.lightbulb, color: Color(0xFFFFC700), size: 16),
            ),
            const SizedBox(width: 12),
            const Text('AI RECOMMENDATIONS',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.w700, color: Color(0xFFFFC700), letterSpacing: 1)),
          ]),
          const SizedBox(height: 16),
          ...actions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.arrow_right, color: Color(0xFFFFC700), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a, style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 13, color: Color(0xFFD3E3FF), height: 1.4)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }

  String _friendlyDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }
}

// ── Small helper widget ───────────────────────────────────────────────────────

class _TrainStep extends StatelessWidget {
  final String label;
  final bool done;

  const _TrainStep({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: done ? const Color(0xFF4CAF50) : const Color(0xFF3A5A7A)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                  color: done ? const Color(0xFFD3E3FF) : const Color(0xFF5A6B7F))),
        ],
      ),
    );
  }
}
