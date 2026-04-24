import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'insights_screen.dart';
import 'alerts_screen.dart';
import 'predictions_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  String? _accountId;

  // Memoized screens — only rebuilt when _accountId changes, not on every setState
  List<Widget>? _cachedScreens;
  String? _cachedAccountId;

  List<Widget> get _screens {
    final accountId = _accountId ?? 'ACC_TEST';
    if (_cachedScreens == null || _cachedAccountId != accountId) {
      _cachedAccountId = accountId;
      _cachedScreens = [
        HomeScreen(accountId: accountId),
        TransactionsScreen(accountId: accountId),
        InsightsScreen(accountId: accountId),
        AlertsScreen(accountId: accountId),
        PredictionsScreen(accountId: accountId),
      ];
    }
    return _cachedScreens!;
  }

  @override
  void initState() {
    super.initState();
    _loadAccountId();
  }

  Future<void> _loadAccountId() async {
    try {
      final accounts = await _apiService.getMyAccounts();
      if (accounts.isNotEmpty && mounted) {
        setState(() {
          _accountId = accounts[0]['account_id'];
        });
      }
    } catch (e) {
      // keep fallback accountId
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Stitch-style Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF102B49).withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00142B).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home,
                  label: 'HOME',
                  isActive: _currentIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history,
                  label: 'HISTORY',
                  isActive: _currentIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.insights,
                  label: 'INSIGHTS',
                  isActive: _currentIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications,
                  label: 'ALERTS',
                  isActive: _currentIndex == 3,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.timeline,
                  label: 'FORECAST',
                  isActive: _currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    color: const Color(0xFF213A59).withOpacity(0.4),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFFEFC100),
                        width: 4,
                      ),
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? const Color(0xFFEFC100)
                      : const Color(0xFFA8C9F6),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isActive
                        ? const Color(0xFFEFC100)
                        : const Color(0xFFA8C9F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
