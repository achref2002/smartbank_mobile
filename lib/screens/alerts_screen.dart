import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class AlertsScreen extends StatefulWidget {
  final String? accountId;

  const AlertsScreen({super.key, this.accountId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _apiService = ApiService();
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.accountId ?? 'ACC_TEST';
      final alerts = await _apiService.getAlerts(id, unresolvedOnly: false);
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _loadAlerts,
                color: const Color(0xFFFFC700),
                backgroundColor: const Color(0xFF162639),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 32),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: CircularProgressIndicator(color: Color(0xFFFFC700)),
                            ),
                          )
                        else if (_alerts.isEmpty)
                          _buildEmptyState()
                        else
                          ..._alerts.map((alert) => _buildAlertCard(alert)),

                        const SizedBox(height: 32),
                        _buildSubscriptionIncrease(),
                        const SizedBox(height: 32),
                        _buildSystemHealth(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0D1B2D),
      pinned: true,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF162639),
          ),
          child: const Icon(Icons.account_circle, color: Color(0xFFFFC700), size: 24),
        ),
      ),
      title: const Text(
        'SmartBank AI',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFFA8C9F6)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDot(),
            const SizedBox(width: 4),
            _buildDot(),
            const SizedBox(width: 4),
            _buildDot(),
            const SizedBox(width: 12),
            const Text(
              'INTELLIGENCE FEED',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFC700),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_alerts.length} active',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Security & Events',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI-driven monitoring of your financial perimeter.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF8B9AAD),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC700),
        borderRadius: BorderRadius.circular(2),
      ),
      transform: Matrix4.rotationZ(0.785398),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
          SizedBox(height: 16),
          Text(
            'All Clear',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No active alerts — your finances look healthy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF8B9AAD),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = (alert['severity'] as String? ?? 'low').toLowerCase();
    final Color borderColor;
    final Color iconColor;
    final IconData icon;

    switch (severity) {
      case 'critical':
        borderColor = const Color(0xFFFFB4AB);
        iconColor = const Color(0xFFFFB4AB);
        icon = Icons.error;
        break;
      case 'high':
        borderColor = const Color(0xFFFF9800);
        iconColor = const Color(0xFFFF9800);
        icon = Icons.warning;
        break;
      case 'medium':
        borderColor = const Color(0xFFFFC700);
        iconColor = const Color(0xFFFFC700);
        icon = Icons.info;
        break;
      default:
        borderColor = const Color(0xFFA8C9F6);
        iconColor = const Color(0xFFA8C9F6);
        icon = Icons.notifications;
    }

    final alertType = (alert['alert_type'] as String? ?? '')
        .replaceAll('_', ' ')
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alertType,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD3E3FF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert['message'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF8B9AAD),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert['alert_date'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF5A6B7F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionIncrease() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.subscriptions, color: Color(0xFFFFC700), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Increase',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cloud Storage: +4.99 €/mo',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF8B9AAD)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showComingSoon('Manage Auto-Pay'),
            child: const Row(
              children: [
                Text(
                  'Manage Auto-Pay',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFC700),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: Color(0xFFFFC700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDot(),
              const SizedBox(width: 4),
              _buildDot(),
              const SizedBox(width: 4),
              _buildDot(),
              const SizedBox(width: 12),
              const Text(
                'SYSTEM HEALTH',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ONLINE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4CAF50),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'All AI Core Models are operational.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last deep scan completed 14 minutes ago.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF8B9AAD),
            ),
          ),
        ],
      ),
    );
  }
}
