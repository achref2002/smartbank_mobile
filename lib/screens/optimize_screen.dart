import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OptimizeScreen extends StatefulWidget {
  final String accountId;
  const OptimizeScreen({super.key, required this.accountId});

  @override
  State<OptimizeScreen> createState() => _OptimizeScreenState();
}

class _OptimizeScreenState extends State<OptimizeScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _linkedAccounts = [];
  String _selectedAccountId = '';
  final Map<String, Map<String, dynamic>?> _dataByAccount = {};
  final Map<String, bool> _loading = {};
  final Set<String> _expanded = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final resp = await _api.getMyAccounts();
      final accounts = (resp is List)
          ? resp.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _linkedAccounts = accounts;
          if (_selectedAccountId.isEmpty && accounts.isNotEmpty) {
            _selectedAccountId = accounts[0]['account_id']?.toString() ?? '';
          }
        });
        if (_selectedAccountId.isNotEmpty) _load(_selectedAccountId);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _load(String accountId) async {
    if (_dataByAccount.containsKey(accountId)) return;
    setState(() { _loading[accountId] = true; _error = null; });
    try {
      final data = await _api.getOptimizeRecommendations(accountId);
      if (mounted) setState(() {
        _dataByAccount[accountId] = data;
        _loading[accountId] = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading[accountId] = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _selectAccount(String id) {
    if (_selectedAccountId == id) return;
    setState(() { _selectedAccountId = id; _error = null; });
    _load(id);
  }

  bool get _isLoading => _loading[_selectedAccountId] == true;
  Map<String, dynamic>? get _data => _dataByAccount[_selectedAccountId];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2D),
        elevation: 0,
        title: const Text('Optimiser mes charges',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFFFC700)),
              onPressed: () {
                _dataByAccount.remove(_selectedAccountId);
                _load(_selectedAccountId);
              },
            ),
        ],
      ),
      body: Column(children: [
        if (_linkedAccounts.length > 1) _buildAccountSelector(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      color: const Color(0xFF0D1B2D),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _linkedAccounts.map((acc) {
            final id = acc['account_id']?.toString() ?? '';
            final sel = _selectedAccountId == id;
            return GestureDetector(
              onTap: () => _selectAccount(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFFFC700) : const Color(0xFF162639),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? const Color(0xFFFFC700) : const Color(0xFF1E3A5F)),
                ),
                child: Text(id,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? const Color(0xFF0A1628) : const Color(0xFFA8C9F6))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || (!_dataByAccount.containsKey(_selectedAccountId))) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC700)));
    }
    if (_error != null && _data == null) return _buildError();

    final data = _data;
    if (data == null) return _buildError();

    final recs = (data['recommendations'] as List? ?? [])
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    final switchable = recs.where((r) => r['type'] == 'switchable').toList();

    return RefreshIndicator(
      onRefresh: () async {
        _dataByAccount.remove(_selectedAccountId);
        await _load(_selectedAccountId);
      },
      color: const Color(0xFFFFC700),
      backgroundColor: const Color(0xFF162639),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(data),
          const SizedBox(height: 20),
          if (switchable.isEmpty && recs.isEmpty) _buildEmpty(),
          ...recs.map((r) => _buildRecommendationCard(r)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final monthly = (data['total_monthly_potential_saving'] as num?)?.toDouble() ?? 0;
    final annual  = (data['total_annual_potential_saving']  as num?)?.toDouble() ?? 0;
    final count   = data['recommendations_count'] as int? ?? 0;
    final high    = data['high_priority_count']   as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162639), Color(0xFF1A3050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC700).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings, color: Color(0xFFFFC700), size: 20),
          const SizedBox(width: 8),
          const Text('ÉCONOMIES POTENTIELLES',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                  fontWeight: FontWeight.w700, color: Color(0xFF8B9AAD), letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(
            text: '${annual.toStringAsFixed(0)} TND',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 36,
                fontWeight: FontWeight.w900, color: Color(0xFFFFC700)),
          ),
          const TextSpan(
            text: ' / an',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                fontWeight: FontWeight.w500, color: Color(0xFF8B9AAD)),
          ),
        ])),
        const SizedBox(height: 4),
        Text('soit ${monthly.toStringAsFixed(0)} TND/mois',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                color: Color(0xFFA8C9F6))),
        const SizedBox(height: 16),
        Row(children: [
          _summaryChip('$count offres trouvées', const Color(0xFF4CAF50)),
          if (high > 0) ...[
            const SizedBox(width: 8),
            _summaryChip('$high priorité haute', const Color(0xFFFF4444)),
          ],
        ]),
      ]),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final type     = rec['type'] as String? ?? 'switchable';
    final priority = rec['priority'] as String? ?? 'none';
    final merchant = rec['merchant_name'] as String? ?? '';
    final category = rec['category'] as String? ?? '';
    final monthly  = (rec['current_monthly_cost'] as num?)?.toDouble() ?? 0;
    final saving   = (rec['best_monthly_saving']  as num?)?.toDouble() ?? 0;
    final annual   = (rec['best_annual_saving']   as num?)?.toDouble() ?? 0;
    final insight  = rec['insight'] as String? ?? '';
    final alts     = (rec['alternatives'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();

    final isExpanded = _expanded.contains(merchant);

    Color borderColor;
    Color priorityColor;
    String priorityLabel;

    switch (priority) {
      case 'high':
        borderColor = const Color(0xFFFF4444);
        priorityColor = const Color(0xFFFF4444);
        priorityLabel = 'PRIORITÉ HAUTE';
        break;
      case 'medium':
        borderColor = const Color(0xFFFFC700);
        priorityColor = const Color(0xFFFFC700);
        priorityLabel = 'PRIORITÉ MOYENNE';
        break;
      case 'low':
        borderColor = const Color(0xFFA8C9F6);
        priorityColor = const Color(0xFFA8C9F6);
        priorityLabel = 'PRIORITÉ FAIBLE';
        break;
      default:
        borderColor = const Color(0xFF2A3F58);
        priorityColor = const Color(0xFF5A6B7F);
        priorityLabel = type == 'non_switchable' ? 'NON SUBSTITUABLE' : 'DÉJÀ OPTIMAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(priorityLabel,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 9,
                        fontWeight: FontWeight.w700, color: priorityColor, letterSpacing: 0.8)),
              ),
              const Spacer(),
              Text(category,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                      color: Color(0xFF5A6B7F))),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Text(merchant,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Text('${monthly.toStringAsFixed(0)} TND/mois',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                      fontWeight: FontWeight.w800, color: Color(0xFFA8C9F6))),
            ]),

            // ── Insight sentence ────────────────────────────────────────────
            if (insight.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(insight,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                      color: Color(0xFF8B9AAD), height: 1.4)),
            ],

            // ── Best saving summary (switchable only) ───────────────────────
            if (type == 'switchable' && saving > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.trending_down, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Économie : ${saving.toStringAsFixed(0)} TND/mois  ·  ${annual.toStringAsFixed(0)} TND/an',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                        fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                  ),
                ]),
              ),
            ],

            // ── Best alternative preview ─────────────────────────────────────
            if (alts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBestAlternativePreview(alts[0]),
            ],

            // ── Expand/collapse button ───────────────────────────────────────
            if (alts.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() =>
                    isExpanded ? _expanded.remove(merchant) : _expanded.add(merchant)),
                child: Row(children: [
                  Text(
                    isExpanded ? 'Masquer les détails' : 'Voir comment changer →',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        fontWeight: FontWeight.w700, color: borderColor),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: borderColor, size: 18,
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 14),
          ]),
        ),

        // ── Expanded detail panel ────────────────────────────────────────────
        if (isExpanded && alts.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2D),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOUTES LES ALTERNATIVES',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 9,
                      fontWeight: FontWeight.w700, color: Color(0xFF5A6B7F), letterSpacing: 1)),
              const SizedBox(height: 12),
              ...alts.map((alt) => _buildAltRow(alt, monthly)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildBestAlternativePreview(Map<String, dynamic> alt) {
    final name     = '${alt['operator']} — ${alt['plan_name']}';
    final price    = (alt['monthly_price'] as num?)?.toDouble() ?? 0;
    final features = (alt['features'] as List? ?? []).take(2).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2030),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Meilleure alternative : ',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF8B9AAD))),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w700, color: Colors.white),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${price.toStringAsFixed(0)} TND/mois',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Color(0xFFFFC700))),
        ]),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: features.map((f) => _featureChip(f.toString())).toList(),
          ),
        ],
      ]),
    );
  }

  Widget _buildAltRow(Map<String, dynamic> alt, double currentCost) {
    final operator   = alt['operator'] as String? ?? '';
    final plan       = alt['plan_name'] as String? ?? '';
    final price      = (alt['monthly_price'] as num?)?.toDouble() ?? 0;
    final saving     = (alt['savings_vs_user'] as num?)?.toDouble() ?? (currentCost - price);
    final difficulty = alt['switch_difficulty'] as String? ?? 'medium';
    final instruct   = alt['switch_instructions'] as String? ?? '';
    final features   = (alt['features'] as List? ?? []);

    Color diffColor;
    String diffLabel;
    switch (difficulty) {
      case 'easy':   diffColor = const Color(0xFF4CAF50); diffLabel = 'Facile';    break;
      case 'hard':   diffColor = const Color(0xFFFF4444); diffLabel = 'Difficile'; break;
      default:       diffColor = const Color(0xFFFFC700); diffLabel = 'Moyen';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('$operator — $plan',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Text('${price.toStringAsFixed(0)} TND/mois',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                  fontWeight: FontWeight.w800, color: Color(0xFFFFC700))),
        ]),
        const SizedBox(height: 6),
        Text('Économie : ${saving.toStringAsFixed(0)} TND/mois',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: features.map((f) => _featureChip(f.toString())).toList(),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: diffColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: diffColor.withOpacity(0.4)),
            ),
            child: Text(diffLabel,
                style: TextStyle(fontFamily: 'Inter', fontSize: 9,
                    fontWeight: FontWeight.w700, color: diffColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(instruct,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                    color: Color(0xFF8B9AAD), height: 1.4)),
          ),
        ]),
      ]),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF213A59),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
              color: Color(0xFFA8C9F6))),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 64),
          const SizedBox(height: 16),
          const Text('Charges déjà optimisées 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 20,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'Aucune meilleure offre trouvée pour vos charges fixes actuelles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                color: Color(0xFF8B9AAD), height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Color(0xFFFFB4AB), size: 48),
          const SizedBox(height: 16),
          Text(_error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                  color: Color(0xFFFFB4AB))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () { _dataByAccount.remove(_selectedAccountId); _load(_selectedAccountId); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC700),
                foregroundColor: const Color(0xFF0A1628)),
            child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
