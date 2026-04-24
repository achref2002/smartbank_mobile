import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final String accountId;

  const TransactionsScreen({super.key, required this.accountId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  // Raw data keyed by account_id
  final Map<String, List<dynamic>> _transactionsByAccount = {};
  List<Map<String, dynamic>> _linkedAccounts = [];

  bool _isLoading = true;

  // Filter state
  String _searchQuery = '';
  String _selectedAccountId = 'all';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiService.getMyAccounts();
      final accounts = (resp is List)
          ? resp.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      _linkedAccounts = accounts;

      // Load transactions for every account in parallel
      final futures = accounts.map((acc) async {
        final id = acc['account_id']?.toString() ?? '';
        if (id.isEmpty) return;
        try {
          final txns = await _apiService.getTransactions(id, limit: 300);
          if (mounted) {
            _transactionsByAccount[id] = List<dynamic>.from(txns);
          }
        } catch (_) {}
      });

      await Future.wait(futures);
    } catch (_) {
      // Fall back to the widget's accountId
      try {
        final txns = await _apiService.getTransactions(widget.accountId, limit: 300);
        _transactionsByAccount[widget.accountId] = List<dynamic>.from(txns);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  List<dynamic> get _filteredTransactions {
    // 1. Select by account
    List<dynamic> all;
    if (_selectedAccountId == 'all') {
      all = _transactionsByAccount.values.expand((list) => list).toList();
    } else {
      all = List<dynamic>.from(_transactionsByAccount[_selectedAccountId] ?? []);
    }

    // 2. Filter by category
    if (_selectedCategory != null) {
      all = all.where((txn) {
        final cat = (txn['category'] ?? txn['category_name'] ?? '').toString().toLowerCase();
        return cat == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // 3. Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      all = all.where((txn) {
        final merchant = (txn['merchant'] ?? txn['description'] ?? txn['counterparty'] ?? '').toString().toLowerCase();
        final cat = (txn['category'] ?? '').toString().toLowerCase();
        final amount = (txn['amount'] ?? 0).toString();
        final desc = (txn['details'] ?? txn['note'] ?? '').toString().toLowerCase();
        return merchant.contains(q) || cat.contains(q) || amount.contains(q) || desc.contains(q);
      }).toList();
    }

    // 4. Sort newest first
    all.sort((a, b) {
      final da = (a['posted_at'] ?? a['date'] ?? '').toString();
      final db = (b['posted_at'] ?? b['date'] ?? '').toString();
      return db.compareTo(da);
    });

    return all;
  }

  List<String> get _allCategories {
    final all = _transactionsByAccount.values.expand((list) => list);
    final cats = all
        .map((txn) => (txn['category'] ?? txn['category_name'] ?? '').toString())
        .where((c) => c.isNotEmpty && c.toLowerCase() != 'null')
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  int get _totalCount => _transactionsByAccount.values.fold(0, (s, l) => s + l.length);

  // ── UI helpers ────────────────────────────────────────────────────────────

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        backgroundColor: const Color(0xFF1C3655),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFilterSheet() {
    final categories = _allCategories;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001C39),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF3A5A7A), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FILTER BY CATEGORY',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Color(0xFFEFC100))),
                  if (_selectedCategory != null)
                    TextButton(
                      onPressed: () {
                        setSheet(() {});
                        setState(() => _selectedCategory = null);
                      },
                      child: const Text('Clear', style: TextStyle(color: Color(0xFFA8C9F6), fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const Text('No categories found.', style: TextStyle(color: Color(0xFF8D919B)))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final selected = _selectedCategory?.toLowerCase() == cat.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        final next = selected ? null : cat;
                        setSheet(() {});
                        setState(() => _selectedCategory = next);
                        if (next != null) Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFEFC100) : const Color(0xFF02203E),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: selected ? const Color(0xFFEFC100) : const Color(0xFF1C3655)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconForCategory(cat), size: 14,
                                color: selected ? const Color(0xFF3C2F00) : const Color(0xFFA8C9F6)),
                            const SizedBox(width: 6),
                            Text(
                              cat.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                                color: selected ? const Color(0xFF3C2F00) : const Color(0xFFA8C9F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
        title: const Text(
          'SmartBank AI',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: const Color(0xFFA8C9F6),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: const Color(0xFFA8C9F6),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFC100)))
          : RefreshIndicator(
              color: const Color(0xFFEFC100),
              backgroundColor: const Color(0xFF001C39),
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildAccountChips(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                  _buildActiveFilters(),
                  const SizedBox(height: 16),
                  ..._buildTransactionCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection() {
    final filtered = _filteredTransactions;
    final income = filtered.where((t) => (t['amount'] ?? 0) > 0).fold<double>(0, (s, t) => s + (t['amount'] as num).toDouble());
    final expense = filtered.where((t) => (t['amount'] ?? 0) < 0).fold<double>(0, (s, t) => s + (t['amount'] as num).toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: const Color(0xFFEFC100), borderRadius: BorderRadius.circular(2)),
              transform: Matrix4.rotationZ(0.785398),
            ),
          ))
            ..add(const Text('TRANSACTION LEDGER',
                style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0xFFEFC100)))),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'Manrope', fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFFD3E3FF), height: 1.1),
            children: [
              TextSpan(text: 'Financial '),
              TextSpan(text: 'Movement.', style: TextStyle(color: Color(0xFFEFC100), fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_totalCount transactions across ${_linkedAccounts.length} account${_linkedAccounts.length != 1 ? 's' : ''}. '
          'Showing ${filtered.length} · Income +${income.toStringAsFixed(0)} TND · Expenses ${expense.toStringAsFixed(0)} TND',
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 14, color: Color(0xFFA8C9F6), height: 1.6),
        ),
      ],
    );
  }

  Widget _buildAccountChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _accountChip('all', 'All Accounts'),
          ..._linkedAccounts.map((acc) {
            final id = acc['account_id']?.toString() ?? '';
            return _accountChip(id, id);
          }),
        ],
      ),
    );
  }

  Widget _accountChip(String id, String label) {
    final selected = _selectedAccountId == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAccountId = id;
        _selectedCategory = null;
        _searchQuery = '';
        _searchController.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFC100) : const Color(0xFF001C39),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFEFC100) : const Color(0xFF1C3655)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF3C2F00) : const Color(0xFFA8C9F6),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF001C39), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFFD3E3FF)),
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search merchant, category or amount…',
                hintStyle: const TextStyle(color: Color(0xFF8D919B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8D919B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF8D919B), size: 18),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFF000F22),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ElevatedButton.icon(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('FILTERS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategory != null ? const Color(0xFFEFC100) : const Color(0xFF1C3655),
                  foregroundColor: _selectedCategory != null ? const Color(0xFF3C2F00) : const Color(0xFFA8C9F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              if (_selectedCategory != null)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: Color(0xFFEF5350), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedCategory == null && _searchQuery.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedCategory != null)
            Chip(
              label: Text(_selectedCategory!.toUpperCase(),
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3C2F00))),
              backgroundColor: const Color(0xFFEFC100),
              deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF3C2F00)),
              onDeleted: () => setState(() => _selectedCategory = null),
            ),
          if (_searchQuery.isNotEmpty)
            Chip(
              label: Text('"$_searchQuery"',
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Color(0xFFA8C9F6))),
              backgroundColor: const Color(0xFF001C39),
              side: const BorderSide(color: Color(0xFF1C3655)),
              deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFA8C9F6)),
              onDeleted: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
              }),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionCards() {
    final txns = _filteredTransactions;

    if (txns.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, color: Color(0xFF3A5A7A), size: 48),
                SizedBox(height: 16),
                Text('No transactions match your filters.',
                    style: TextStyle(color: Color(0xFF8D919B), fontFamily: 'Manrope', fontSize: 14)),
              ],
            ),
          ),
        ),
      ];
    }

    return txns.map((txn) {
      final merchant = (txn['merchant'] ?? txn['description'] ?? txn['counterparty'] ?? 'Transaction').toString();
      final details = (txn['details'] ?? txn['description'] ?? txn['note'] ?? '').toString();
      final category = (txn['category'] ?? txn['category_name'] ?? 'Other').toString();
      final date = (txn['posted_at'] ?? txn['date'] ?? txn['timestamp'] ?? '').toString();
      final amount = (txn['amount'] is num)
          ? (txn['amount'] as num).toDouble()
          : double.tryParse(txn['amount']?.toString() ?? '0') ?? 0.0;

      return _buildTransactionCard({
        'merchant': merchant,
        'details': details.isNotEmpty && details != merchant ? details : _formatDate(date),
        'category': category,
        'date': date,
        'amount': amount,
        'icon': _iconForCategory(category),
      });
    }).toList();
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  IconData _iconForCategory(String category) {
    final key = category.toLowerCase();
    if (key.contains('groc')) return Icons.shopping_cart;
    if (key.contains('util') || key.contains('energy')) return Icons.bolt;
    if (key.contains('income') || key.contains('salary')) return Icons.payments;
    if (key.contains('transport') || key.contains('travel') || key.contains('taxi') || key.contains('uber')) return Icons.directions_bus;
    if (key.contains('dining') || key.contains('restaurant') || key.contains('food')) return Icons.restaurant;
    if (key.contains('entertainment') || key.contains('media') || key.contains('streaming')) return Icons.play_circle;
    if (key.contains('shopping') || key.contains('retail')) return Icons.shopping_bag;
    if (key.contains('telecom') || key.contains('phone') || key.contains('mobile')) return Icons.phone_android;
    if (key.contains('cash') || key.contains('withdrawal') || key.contains('atm')) return Icons.atm;
    if (key.contains('health') || key.contains('medical') || key.contains('pharmacy')) return Icons.local_hospital;
    if (key.contains('education') || key.contains('school')) return Icons.school;
    if (key.contains('insurance')) return Icons.shield;
    return Icons.receipt_long;
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = (transaction['amount'] as double) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF02203E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showComingSoon('Transaction details'),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF213A59),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF1C3655), borderRadius: BorderRadius.circular(8)),
                  child: Icon(transaction['icon'] as IconData, color: const Color(0xFFEFC100), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['merchant'] as String,
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD3E3FF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        transaction['details'] as String,
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Color(0xFFA8C9F6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : ''}${(transaction['amount'] as double).toStringAsFixed(2)} TND',
                      style: TextStyle(
                        fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800,
                        color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFEFC100),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isIncome ? const Color(0xFFEFC100).withOpacity(0.15) : const Color(0xFF213A59),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (transaction['category'] as String).toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Manrope', fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                          color: isIncome ? const Color(0xFFEFC100) : const Color(0xFFA8C9F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
