import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String accountId;
  
  const HomeScreen({super.key, required this.accountId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _realBalance;
  List<dynamic> _recurringCharges = [];
  List<dynamic> _alerts = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user info
      _user = await _apiService.getCurrentUser();
      
      // Load account data
      await _loadAccountData();
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        _logout();
      } else {
        _showError(e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAccountData() async {
    try {
      final balance = _apiService.getRealBalance(widget.accountId);
      final recurring = _apiService.getRecurringCharges(widget.accountId);
      final alerts = _apiService.getAlerts(widget.accountId);

      final results = await Future.wait([balance, recurring, alerts]);
      
      setState(() {
        _realBalance = results[0] as Map<String, dynamic>;
        _recurringCharges = results[1] as List<dynamic>;
        _alerts = results[2] as List<dynamic>;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        backgroundColor: const Color(0xFF1C3655),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openClassifySheet() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    Map<String, dynamic>? result;
    bool isClassifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF162639),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> classify() async {
              if (descController.text.trim().isEmpty) return;
              setSheetState(() { isClassifying = true; result = null; });
              try {
                final res = await _apiService.classify(
                  description: descController.text.trim(),
                  amount: double.tryParse(amountController.text) ?? 0.0,
                );
                setSheetState(() { result = res; isClassifying = false; });
              } catch (e) {
                setSheetState(() => isClassifying = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category, color: Color(0xFFEFC100)),
                      const SizedBox(width: 12),
                      const Text(
                        'CLASSIFY TRANSACTION',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF8D919B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Transaction description',
                      labelStyle: const TextStyle(color: Color(0xFF8D919B)),
                      filled: true,
                      fillColor: const Color(0xFF02203E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'e.g. Netflix subscription',
                      hintStyle: const TextStyle(color: Color(0xFF5A6B7F)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (optional)',
                      labelStyle: const TextStyle(color: Color(0xFF8D919B)),
                      filled: true,
                      fillColor: const Color(0xFF02203E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixText: '€ ',
                      prefixStyle: const TextStyle(color: Color(0xFFEFC100)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isClassifying ? null : classify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFC100),
                        foregroundColor: const Color(0xFF0A1628),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isClassifying
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A1628),
                              ),
                            )
                          : const Text(
                              'CLASSIFY',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF02203E),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFEFC100), width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                result!['category'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEFC100),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFC100).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${((result!['confidence'] as double) * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEFC100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'via ${result!['method']} • ${result!['cached'] == true ? 'cached' : 'live'}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: Color(0xFF8D919B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00142B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001C39),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEFC100).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.account_circle,
                color: Color(0xFFEFC100),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SmartBank AI',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color(0xFFD3E3FF),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFA8C9F6)),
            onPressed: () => _showComingSoon('Search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFA8C9F6)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFC100)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFEFC100),
              backgroundColor: const Color(0xFF1C3655),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Card
                  if (_user != null)
                    Card(
                      color: const Color(0xFF1C3655),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: Color(0xFFA8C9F6),
                              ),
                            ),
                            Text(
                              _user!['full_name'] ?? _user!['username'],
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD3E3FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Real Balance Card
                  if (_realBalance != null) _buildRealBalanceCard(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Alerts Section
                  if (_alerts.isNotEmpty) ...[
                    _buildSectionHeader('Alerts', Icons.warning_amber, _alerts.length),
                    ..._alerts.take(3).map((alert) => _buildAlertCard(alert)),
                    const SizedBox(height: 16),
                  ],

                  // Recurring Charges Section
                  if (_recurringCharges.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Charges', Icons.repeat, _recurringCharges.length),
                    ..._recurringCharges.take(5).map((charge) => _buildRecurringChargeCard(charge)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRealBalanceCard() {
    final currentBalance = _realBalance!['current_balance'];
    final realBalance = _realBalance!['real_balance'];
    final pending = _realBalance!['pending_recurring'];

    return Card(
      elevation: 4,
      color: const Color(0xFF1C3655),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C3655),
              const Color(0xFF213A59).withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Real Balance',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA8C9F6),
                    ),
                  ),
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFFEFC100),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${realBalance.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: realBalance < 0
                      ? const Color(0xFFFFB4AB)
                      : const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Color(0xFF8D919B),
                        ),
                      ),
                      Text(
                        '${currentBalance.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD3E3FF),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Pending',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Color(0xFF8D919B),
                        ),
                      ),
                      Text(
                        '${pending.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pending.abs() / currentBalance.abs().clamp(1, double.infinity),
                  backgroundColor: const Color(0xFF02203E),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Classify',
            Icons.category,
            const Color(0xFFEFC100),
            () => _openClassifySheet(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Optimize',
            Icons.savings,
            const Color(0xFF4CAF50),
            () => _showComingSoon('Optimize savings'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1C3655),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFEFC100)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD3E3FF),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFC100).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEFC100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    Color color;
    IconData icon;
    
    switch (alert['severity']) {
      case 'WARNING':
        color = const Color(0xFFFF9800);
        icon = Icons.warning;
        break;
      case 'CRITICAL':
        color = const Color(0xFFFFB4AB);
        icon = Icons.error;
        break;
      default:
        color = const Color(0xFFA8C9F6);
        icon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1C3655),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          alert['alert_type'].replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD3E3FF),
          ),
        ),
        subtitle: Text(
          alert['message'],
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: Color(0xFFA8C9F6),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            alert['severity'],
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringChargeCard(Map<String, dynamic> charge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1C3655),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF213A59),
          child: const Icon(Icons.repeat, color: Color(0xFFEFC100)),
        ),
        title: Text(
          charge['merchant_name'],
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD3E3FF),
          ),
        ),
        subtitle: Text(
          'Next: ${charge['next_expected_date']} • Every ${charge['cadence_days']} days',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: Color(0xFFA8C9F6),
          ),
        ),
        trailing: Text(
          '${charge['avg_amount'].toStringAsFixed(2)} €',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFFEFC100),
          ),
        ),
      ),
    );
  }
}
