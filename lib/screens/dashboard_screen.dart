import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/alert_card.dart';
import '../widgets/transaction_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _accountId;
  Map<String, dynamic>? _realBalance;
  List<dynamic> _recentTransactions = [];
  List<dynamic> _recurringCharges = [];
  
  // Mock data for dashboard
  final double _totalAssets = 248592.45;
  final double _netGrowth = 12.4;
  final List<double> _growthData = [0.6, 0.7, 0.65, 0.75, 0.85, 1.0];
  final double _savingsGoal = 4500;
  final double _savingsTarget = 6000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user and account info
      _user = await _apiService.getCurrentUser();
      final accounts = await _apiService.getMyAccounts();
      
      if (accounts.isNotEmpty) {
        _accountId = accounts[0]['account_id'];
        
        // Load real balance
        _realBalance = await _apiService.getRealBalance(_accountId!);
        
        _recurringCharges = await _apiService.getRecurringCharges(_accountId!);
        
        // Mock recent transactions (you can fetch real ones when endpoint is ready)
        _recentTransactions = [
          {
            'merchant': 'Apple Store Regent St.',
            'details': 'TECHNOLOGY • 2 HOURS AGO',
            'category': 'Technology',
            'date': '42291',
            'amount': -1299.00,
            'icon': Icons.shopping_bag,
            'isIncome': false,
          },
          {
            'merchant': 'Meta Platforms Inc.',
            'details': 'DIVIDEND CREDIT • YESTERDAY',
            'category': 'Income',
            'date': '9001',
            'amount': 450.25,
            'icon': Icons.account_balance,
            'isIncome': true,
          },
          {
            'merchant': 'The Wolseley London',
            'details': 'DINING • 2 DAYS AGO',
            'category': 'Dining',
            'date': '9001',
            'amount': -184.50,
            'icon': Icons.restaurant,
            'isIncome': false,
          },
        ];
      }
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFC700),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFFFFC700),
                backgroundColor: const Color(0xFF162639),
                child: CustomScrollView(
                  slivers: [
                    // Header with FOCUS logo
                    _buildHeader(),
                    
                    // Main content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Liquid Assets
                            _buildTotalAssets(),
                            const SizedBox(height: 24),
                            
                            // Action buttons
                            _buildActionButtons(),
                            const SizedBox(height: 32),
                            
                            // Net Growth with chart
                            _buildNetGrowth(),
                            const SizedBox(height: 32),
                            
                            // AI Intelligence Alert
                            _buildAIAlert(),
                            const SizedBox(height: 32),
                            
                            // Savings Goal Gauge
                            _buildSavingsGoal(),
                            const SizedBox(height: 32),
                            
                            // Recent Transactions
                            _buildRecentTransactions(),
                            const SizedBox(height: 32),
                            
                            // Portfolio Health
                            _buildPortfolioHealth(),
                            const SizedBox(height: 32),
                            
                            // Advanced Wealth Analysis
                            _buildWealthAnalysis(),
                            const SizedBox(height: 80), // Space for bottom nav
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0D1B2D),
      pinned: true,
      elevation: 0,
      title: Row(
        children: [
          // FOCUS Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF162639),
            ),
            child: const Icon(
              Icons.account_circle,
              color: Color(0xFFFFC700),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'SmartBank AI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.settings,
            color: Color(0xFFFFC700),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTotalAssets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 12,
                    color: Color(0xFFFFC700),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'TOTAL LIQUID ASSETS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFC700),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '\$${_totalAssets.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC700),
              foregroundColor: const Color(0xFF0A1628),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Transfer Funds',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(
                color: Color(0xFF1E3A5F),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Manage Cards',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetGrowth() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFFFC700),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET GROWTH (14D)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B9AAD),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_netGrowth.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4CAF50),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GrowthChart(values: _growthData),
        ],
      ),
    );
  }

  Widget _buildAIAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFC700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFFFFC700),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI INTELLIGENCE ALERT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Active Now',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Unusual Spending Pattern Detected',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF8B9AAD),
                height: 1.6,
              ),
              children: [
                TextSpan(text: 'We noticed a 15% increase in your "Lifestyle" category compared to your 3-month average. Based on your goals, we suggest moving '),
                TextSpan(
                  text: '\$1,200',
                  style: TextStyle(
                    color: Color(0xFFFFC700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' to your High-Yield Savings to maintain your growth trajectory.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF0A1628),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Execute Advice',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Dismiss',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B9AAD),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoal() {
    return Center(
      child: SavingsGoalGauge(
        current: _savingsGoal,
        target: _savingsTarget,
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    size: 12,
                    color: Color(0xFFFFC700),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text(
                    'VIEW ALL ARCHIVE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFC700),
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: Color(0xFFFFC700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._recentTransactions.map((txn) {
          return TransactionCard(
            merchantName: txn['merchant'],
            details: txn['details'],
            category: txn['category'],
            date: txn['date'],
            amount: txn['amount'],
            icon: txn['icon'],
            isIncome: txn['isIncome'],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPortfolioHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up,
              color: Color(0xFFFFC700),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Portfolio Health',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildHealthBar('Diversification', 0.85, 'Optimum'),
        const SizedBox(height: 16),
        _buildHealthBar('Risk Score', 0.65, 'Balanced'),
      ],
    );
  }

  Widget _buildHealthBar(String label, double value, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B9AAD),
              ),
            ),
            Text(
              status,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFC700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFF1E3A5F),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC700)),
          ),
        ),
      ],
    );
  }

  Widget _buildWealthAnalysis() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Wealth Analysis',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a comprehensive audit of your digital assets using AI.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF8B9AAD),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.bar_chart,
                size: 48,
                color: const Color(0xFF1E3A5F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
