import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InsightsScreen extends StatefulWidget {
  final String accountId;

  const InsightsScreen({super.key, required this.accountId});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _apiService = ApiService();

  // Raw data keyed by account_id
  final Map<String, List<dynamic>> _transactionsByAccount = {};
  final Map<String, List<dynamic>> _recurringByAccount = {};
  List<Map<String, dynamic>> _linkedAccounts = [];

  bool _isLoading = true;
  String? _error;

  // Selectors
  String _selectedAccountId = 'all';
  late DateTime _selectedMonth;

  static const _categoryColors = [
    Color(0xFFEFC100),
    Color(0xFF4CAF50),
    Color(0xFFA8C9F6),
    Color(0xFFFFB4AB),
    Color(0xFF80CBC4),
    Color(0xFFCE93D8),
    Color(0xFFFFCC80),
    Color(0xFF90CAF9),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadAll();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await _apiService.getMyAccounts();
      final accounts = (resp is List)
          ? resp.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      if (mounted) _linkedAccounts = accounts;

      // Load both transactions and recurring for every account in parallel
      final futures = accounts.map((acc) async {
        final id = acc['account_id']?.toString() ?? '';
        if (id.isEmpty) return;
        await Future.wait([
          _apiService.getTransactions(id, limit: 500).then((txns) {
            if (mounted) _transactionsByAccount[id] = List<dynamic>.from(txns);
          }).catchError((_) {}),
          _apiService.getRecurringCharges(id, activeOnly: false).then((r) {
            if (mounted) _recurringByAccount[id] = List<dynamic>.from(r);
          }).catchError((_) {}),
        ]);
      });

      await Future.wait(futures);

      // Fallback: if no accounts from API, try widget.accountId
      if (accounts.isEmpty) {
        await Future.wait([
          _apiService.getTransactions(widget.accountId, limit: 500).then((t) {
            _transactionsByAccount[widget.accountId] = List<dynamic>.from(t);
          }).catchError((_) {}),
          _apiService.getRecurringCharges(widget.accountId, activeOnly: false).then((r) {
            _recurringByAccount[widget.accountId] = List<dynamic>.from(r);
          }).catchError((_) {}),
        ]);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  List<dynamic> get _selectedTransactions {
    if (_selectedAccountId == 'all') {
      return _transactionsByAccount.values.expand((l) => l).toList();
    }
    return _transactionsByAccount[_selectedAccountId] ?? [];
  }

  List<dynamic> get _selectedRecurring {
    if (_selectedAccountId == 'all') {
      // Deduplicate by merchant_name across accounts
      final seen = <String>{};
      final result = <dynamic>[];
      for (final list in _recurringByAccount.values) {
        for (final r in list) {
          final key = (r['merchant_name'] ?? '').toString().toLowerCase();
          if (seen.add(key)) result.add(r);
        }
      }
      return result;
    }
    return _recurringByAccount[_selectedAccountId] ?? [];
  }

  List<dynamic> get _monthlyTransactions {
    return _selectedTransactions.where((txn) {
      final raw = (txn['posted_at'] ?? txn['date'] ?? '').toString();
      try {
        final dt = DateTime.parse(raw);
        return dt.year == _selectedMonth.year && dt.month == _selectedMonth.month;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get _monthlySpend {
    return _monthlyTransactions
        .where((t) => (t['amount'] ?? 0) < 0)
        .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble().abs());
  }

  double get _monthlyIncome {
    return _monthlyTransactions
        .where((t) => (t['amount'] ?? 0) > 0)
        .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
  }

  double get _avgDailySpend {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final now = DateTime.now();
    final daysPassed = (_selectedMonth.year == now.year && _selectedMonth.month == now.month)
        ? now.day.toDouble()
        : daysInMonth.toDouble();
    return daysPassed > 0 ? _monthlySpend / daysPassed : 0;
  }

  List<Map<String, dynamic>> get _categoryBreakdown {
    final totals = <String, double>{};
    for (final txn in _monthlyTransactions) {
      if ((txn['amount'] ?? 0) >= 0) continue;
      final cat = (txn['category'] ?? txn['category_name'] ?? 'Other').toString();
      totals[cat] = (totals[cat] ?? 0) + (txn['amount'] as num).toDouble().abs();
    }
    final total = totals.values.fold(0.0, (s, v) => s + v);
    final list = totals.entries.map((e) => {
      'category': e.key,
      'total': e.value,
      'percentage': total > 0 ? (e.value / total * 100) : 0.0,
    }).toList();
    list.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return list;
  }

  String get _monthLabel {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _prevMonth() => setState(() =>
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  void _showMonthPicker() {
    // Determine the range of years that have transaction data
    final allTxns = _selectedAccountId == 'all'
        ? _transactionsByAccount.values.expand((l) => l).toList()
        : (_transactionsByAccount[_selectedAccountId] ?? []);

    int minYear = _selectedMonth.year - 2;
    int maxYear = DateTime.now().year;

    if (allTxns.isNotEmpty) {
      final years = allTxns.map((t) {
        final raw = (t['posted_at'] ?? t['date'] ?? '').toString();
        try { return DateTime.parse(raw).year; } catch (_) { return 0; }
      }).where((y) => y > 0).toList();
      if (years.isNotEmpty) {
        minYear = years.reduce((a, b) => a < b ? a : b);
        maxYear = years.reduce((a, b) => a > b ? a : b);
      }
    }

    int pickerYear = _selectedMonth.year;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001C39),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFF3A5A7A), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                // Year row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFFA8C9F6)),
                      onPressed: pickerYear > minYear ? () => setSheet(() => pickerYear--) : null,
                    ),
                    Text(pickerYear.toString(),
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 20,
                            fontWeight: FontWeight.w800, color: Color(0xFFD3E3FF))),
                    IconButton(
                      icon: Icon(Icons.chevron_right,
                          color: pickerYear < maxYear ? const Color(0xFFA8C9F6) : const Color(0xFF2A3A4A)),
                      onPressed: pickerYear < maxYear ? () => setSheet(() => pickerYear++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Month grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final isSelected = pickerYear == _selectedMonth.year && (i + 1) == _selectedMonth.month;
                    final now = DateTime.now();
                    final isFuture = DateTime(pickerYear, i + 1).isAfter(DateTime(now.year, now.month));
                    return GestureDetector(
                      onTap: isFuture ? null : () {
                        setState(() => _selectedMonth = DateTime(pickerYear, i + 1));
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFC100)
                              : isFuture
                                  ? const Color(0xFF001225)
                                  : const Color(0xFF02203E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFEFC100) : const Color(0xFF1C3655),
                          ),
                        ),
                        child: Center(
                          child: Text(months[i],
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF3C2F00)
                                    : isFuture
                                        ? const Color(0xFF3A5A7A)
                                        : const Color(0xFFD3E3FF),
                              )),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00142B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001C39),
        elevation: 0,
        title: const Text('Insights',
            style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD3E3FF))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA8C9F6)),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFC100)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: const Color(0xFFEFC100),
                  backgroundColor: const Color(0xFF001C39),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildAccountChips(),
                      const SizedBox(height: 16),
                      _buildMonthSelector(),
                      const SizedBox(height: 20),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Spending by Category', Icons.pie_chart),
                      const SizedBox(height: 12),
                      _buildCategorySection(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Top Recurring Charges', Icons.repeat),
                      const SizedBox(height: 12),
                      _buildRecurringSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFF3A5A7A), size: 56),
            const SizedBox(height: 16),
            Text(_error ?? 'Failed to load',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8D919B), fontFamily: 'Manrope')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFC100), foregroundColor: const Color(0xFF3C2F00)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('all', 'All Accounts'),
          ..._linkedAccounts.map((acc) {
            final id = acc['account_id']?.toString() ?? '';
            return _chip(id, id);
          }),
        ],
      ),
    );
  }

  Widget _chip(String id, String label) {
    final selected = _selectedAccountId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFC100) : const Color(0xFF001C39),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFEFC100) : const Color(0xFF1C3655)),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF3C2F00) : const Color(0xFFA8C9F6),
            )),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001C39),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C3655)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFFA8C9F6)),
            onPressed: _prevMonth,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showMonthPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_monthLabel,
                            style: const TextStyle(fontFamily: 'Manrope', fontSize: 16,
                                fontWeight: FontWeight.w800, color: Color(0xFFD3E3FF))),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more, color: Color(0xFFA8C9F6), size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${_monthlyTransactions.length} transactions — tap to pick month',
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 10, color: Color(0xFF8D919B))),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: _canGoNext ? const Color(0xFFA8C9F6) : const Color(0xFF2A3A4A)),
            onPressed: _canGoNext ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard('Monthly Spend', '${_monthlySpend.toStringAsFixed(2)} TND',
                Icons.trending_down, const Color(0xFFFFB4AB))),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Monthly Income', '${_monthlyIncome.toStringAsFixed(2)} TND',
                Icons.trending_up, const Color(0xFF4CAF50))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryCard('Subscriptions', '${_selectedRecurring.length}',
                Icons.repeat, const Color(0xFFEFC100))),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Avg Daily Spend', '${_avgDailySpend.toStringAsFixed(2)} TND',
                Icons.calendar_today, const Color(0xFFA8C9F6))),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001C39),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C3655)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Color(0xFF8D919B))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFEFC100)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFD3E3FF))),
      ],
    );
  }

  Widget _buildCategorySection() {
    final breakdown = _categoryBreakdown;
    if (breakdown.isEmpty) {
      return _emptyCard('No expense data for $_monthLabel');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001C39),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C3655)),
      ),
      child: Column(
        children: breakdown.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final color = _categoryColors[i % _categoryColors.length];
          final pct = (item['percentage'] as double);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(item['category'].toString(),
                            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13,
                                fontWeight: FontWeight.w700, color: Color(0xFFD3E3FF))),
                      ],
                    ),
                    Text(
                      '${(item['total'] as double).toStringAsFixed(2)} TND  (${pct.toInt()}%)',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 12,
                          fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct / 100),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      backgroundColor: const Color(0xFF02203E),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecurringSection() {
    final recurring = _selectedRecurring;
    if (recurring.isEmpty) {
      return _emptyCard('No recurring charges detected.\nOpen Insights after loading transactions — detection runs automatically.');
    }

    // Sort by absolute avg_amount descending (largest expense first)
    final sorted = List<dynamic>.from(recurring)
      ..sort((a, b) {
        final ba = ((b['avg_amount'] as num?)?.toDouble() ?? 0).abs();
        final aa = ((a['avg_amount'] as num?)?.toDouble() ?? 0).abs();
        return ba.compareTo(aa);
      });

    return Column(
      children: sorted.take(10).map((charge) => _recurringCard(charge)).toList(),
    );
  }

  Widget _recurringCard(Map<String, dynamic> charge) {
    final name = (charge['merchant_name'] ?? charge['merchant'] ?? 'Unknown').toString();
    final cat = (charge['category'] ?? 'Other').toString();
    final amount = ((charge['avg_amount'] as num?)?.toDouble() ?? 0.0).abs();
    final cadence = charge['cadence_days']?.toString() ?? '?';
    // API returns 'active'; guard against 'is_active' variant too
    final isActive = (charge['active'] ?? charge['is_active'] ?? true) as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF001C39),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1C3655)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF213A59), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.autorenew, color: Color(0xFFEFC100), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontFamily: 'Manrope', fontSize: 14,
                        fontWeight: FontWeight.w700, color: Color(0xFFD3E3FF)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(cat, style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Color(0xFFA8C9F6))),
                    const Text(' · ', style: TextStyle(color: Color(0xFF3A5A7A))),
                    Text('Every $cadence days',
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Color(0xFF8D919B))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${amount.toStringAsFixed(2)} TND',
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 15,
                      fontWeight: FontWeight.w800, color: Color(0xFFEFC100))),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF8D919B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF8D919B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF001C39),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C3655)),
      ),
      child: Center(
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Color(0xFF8D919B), height: 1.5)),
      ),
    );
  }
}
