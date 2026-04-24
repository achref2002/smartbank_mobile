import 'package:flutter/material.dart';
import '../widgets/custom_toggle.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../models/balance_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();

  Future<void> _signOut() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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

  bool _twoFactorAuth = true;
  bool _privacyShield = false;
  bool _predictiveAlerts = true;
  bool _smartInsights = true;
  bool _transactionAlerts = true;
  bool _marketingEmails = false;
  String _modelVerbosity = 'Concise';

  List<dynamic> _linkedAccounts = [];
  bool _accountsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _apiService.getMyAccounts();
      if (mounted) setState(() { _linkedAccounts = accounts; _accountsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _accountsLoading = false);
    }
  }

  void _showLinkAccountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162639),
        title: const Text('Link Existing Account', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the account ID (e.g. ACC_00002)', style: TextStyle(color: Color(0xFF8B9AAD), fontFamily: 'Inter', fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ACC_00002',
                hintStyle: const TextStyle(color: Color(0xFF5A6B7F)),
                filled: true,
                fillColor: const Color(0xFF0D1B2D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9AAD)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC700), foregroundColor: const Color(0xFF0A1628)),
            onPressed: () async {
              final id = controller.text.trim().toUpperCase();
              if (id.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _apiService.linkAccount(id);
                await _loadAccounts();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Linked to $id'), backgroundColor: const Color(0xFF4CAF50)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFFFB4AB)));
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog() {
    final idController = TextEditingController();
    String selectedProfile = 'personal';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF162639),
          title: const Text('Create New Account', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a unique account ID', style: TextStyle(color: Color(0xFF8B9AAD), fontFamily: 'Inter', fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ACC_MYACCOUNT',
                  hintStyle: const TextStyle(color: Color(0xFF5A6B7F)),
                  filled: true,
                  fillColor: const Color(0xFF0D1B2D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              const Text('Profile', style: TextStyle(color: Color(0xFF8B9AAD), fontFamily: 'Inter', fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['personal', 'student', 'professional', 'business'].map((p) =>
                  ChoiceChip(
                    label: Text(p, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: selectedProfile == p ? const Color(0xFF0A1628) : Colors.white)),
                    selected: selectedProfile == p,
                    selectedColor: const Color(0xFFFFC700),
                    backgroundColor: const Color(0xFF0D1B2D),
                    onSelected: (_) => setDialogState(() => selectedProfile = p),
                  )
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9AAD)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC700), foregroundColor: const Color(0xFF0A1628)),
              onPressed: () async {
                final id = idController.text.trim().toUpperCase();
                if (id.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _apiService.createAndLinkAccount(id, profile: selectedProfile);
                  await _loadAccounts();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account $id created and linked'), backgroundColor: const Color(0xFF4CAF50)));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFFFB4AB)));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildAccountManagement(),
                    const SizedBox(height: 24),
                    _buildAccountSecurity(),
                    const SizedBox(height: 24),
                    _buildAIEngine(),
                    const SizedBox(height: 24),
                    _buildAlertCenter(),
                    const SizedBox(height: 24),
                    _buildSmartPlatinumCard(),
                    const SizedBox(height: 24),
                    _buildConciseSupport(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 100),
                  ],
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
        style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFFA8C9F6)),
          onPressed: _signOut,
          tooltip: 'Sign out',
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E3A5F),
            ),
            child: const Icon(Icons.person, color: Color(0xFFFFC700), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alexander Knight',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'alexander.k@smartbank.ai',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF8B9AAD),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXECUTIVE TIER',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagement() {
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
              const Icon(Icons.account_balance_wallet, color: Color(0xFFFFC700), size: 20),
              const SizedBox(width: 12),
              const Text(
                'LINKED ACCOUNTS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (_accountsLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFC700))),
            ],
          ),
          const SizedBox(height: 16),
          if (!_accountsLoading && _linkedAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No accounts linked yet.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF8B9AAD)),
              ),
            ),
          ..._linkedAccounts.map((acc) {
            final id = acc['account_id']?.toString() ?? '';
            final role = acc['role']?.toString() ?? 'owner';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFFA8C9F6), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(id, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text(role.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF8B9AAD), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D3320),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showLinkAccountDialog,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Link Existing', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA8C9F6),
                    side: const BorderSide(color: Color(0xFF1E3A5F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateAccountDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create New', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF0A1628),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurity() {
    return _buildSection(
      icon: Icons.security,
      title: 'ACCOUNT SECURITY',
      children: [
        _buildToggleItem('Two-Factor Authentication', 'Biometric or hardware key required', _twoFactorAuth, (val) => setState(() => _twoFactorAuth = val)),
        _buildToggleItem('Privacy Shield', 'Anonymize transaction metadata', _privacyShield, (val) => setState(() => _privacyShield = val)),
        _buildNavItem('Login History', 'Review recent active sessions', () => _showComingSoon('Login history')),
      ],
    );
  }

  Widget _buildAIEngine() {
    return _buildSection(
      icon: Icons.psychology,
      title: 'AI INTELLIGENCE ENGINE',
      children: [
        _buildModelSelector(),
        const SizedBox(height: 16),
        _buildToggleItem('Predictive Alerts', 'AI will analyze upcoming subscription renewals 48 hours in advance', _predictiveAlerts, (val) => setState(() => _predictiveAlerts = val)),
      ],
    );
  }

  Widget _buildAlertCenter() {
    return _buildSection(
      icon: Icons.notifications,
      title: 'ALERT CENTER',
      children: [
        _buildToggleItem('Smart Insights', '', _smartInsights, (val) => setState(() => _smartInsights = val)),
        _buildToggleItem('Transaction Alerts', '', _transactionAlerts, (val) => setState(() => _transactionAlerts = val)),
        _buildToggleItem('Marketing Emails', '', _marketingEmails, (val) => setState(() => _marketingEmails = val)),
      ],
    );
  }

  Widget _buildSection({required IconData icon, required String title, required List<Widget> children}) {
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
              Icon(icon, color: const Color(0xFFFFC700), size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: const Color(0xFF1E3A5F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF8B9AAD),
                    ),
                  ),
                ],
              ],
            ),
          ),
          CustomToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.history, color: const Color(0xFF1E3A5F), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF8B9AAD),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF5A6B7F), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODEL VERBOSITY',
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
          children: [
            _buildModelButton('Concise', _modelVerbosity == 'Concise'),
            const SizedBox(width: 8),
            _buildModelButton('Balanced', _modelVerbosity == 'Balanced'),
            const SizedBox(width: 8),
            _buildModelButton('Analytical', _modelVerbosity == 'Analytical'),
          ],
        ),
      ],
    );
  }

  Widget _buildModelButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modelVerbosity = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC700) : const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF0A1628) : const Color(0xFF8B9AAD),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartPlatinumCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC700), Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.credit_card,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contactless, color: const Color(0xFF0A1628), size: 24),
                    const Spacer(),
                    const Text(
                      'SMART PLATINUM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A1628),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'ACTIVE CARD',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A6B7F),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '•••• •••• •••• ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A1628),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Text(
                      '8824',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A1628),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConciseSupport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic, color: Color(0xFFFFC700), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Concise Support',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Need assistance with your executive account? Our AI concierge is available 24/7.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF8B9AAD),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showComingSoon('Secure chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Open Secure Chat',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '© 2026 SmartBank AI Corporation, a 2.0-stable',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF5A6B7F),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _showComingSoon('Account deactivation'),
              child: const Text(
                'DEACTIVATE ACCOUNT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B9AAD),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _signOut,
              child: const Text(
                'SIGN OUT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB4AB),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------------- Gemini Monitoring Section ---------------------------
class GeminiMonitoringSection extends StatefulWidget {
  const GeminiMonitoringSection({Key? key}) : super(key: key);

  @override
  State<GeminiMonitoringSection> createState() => _GeminiMonitoringSectionState();
}

class _GeminiMonitoringSectionState extends State<GeminiMonitoringSection> {
  final ApiService _apiService = ApiService();
  
  ClassifierStats? _classifierStats;
  GeminiStats? _geminiStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final classifier = await _apiService.getClassifierStats();
      final gemini = await _apiService.getGeminiStats();
      
      setState(() {
        _classifierStats = classifier;
        _geminiStats = gemini;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _resetStats() async {
    try {
      await _apiService.resetClassifierStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statistiques réinitialisées'),
          backgroundColor: Colors.green,
        ),
      );
      _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      children: [
        // Classifier Stats
        if (_classifierStats != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques de Classification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Total: ${_classifierStats!.totalClassifications}'),
                  const Divider(),
                  _buildLayerStat(
                    'Couche 1 (Règles)',
                    _classifierStats!.layer1Rules,
                    _classifierStats!.layer1Percentage,
                    Colors.green,
                  ),
                  _buildLayerStat(
                    'Couche 2 (Embeddings)',
                    _classifierStats!.layer2Embeddings,
                    _classifierStats!.layer2Percentage,
                    Colors.blue,
                  ),
                  _buildLayerStat(
                    'Couche 3 (ML)',
                    _classifierStats!.layer3MlModel,
                    _classifierStats!.layer3Percentage,
                    Colors.orange,
                  ),
                  _buildLayerStat(
                    'Couche 4 (Gemini)',
                    _classifierStats!.layer4Gemini,
                    _classifierStats!.layer4Percentage,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
        ],

        // Gemini Stats
        if (_geminiStats != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gemini API',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadStats,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Appels API', '${_geminiStats!.totalCalls}'),
                  _buildStatRow('Cache hits', '${_geminiStats!.cacheHits}'),
                  _buildStatRow(
                    'Taux de cache',
                    '${(_geminiStats!.cacheHitRate * 100).toStringAsFixed(1)}%',
                  ),
                  _buildStatRow('Erreurs', '${_geminiStats!.errors}'),
                  _buildStatRow('Tokens', '${_geminiStats!.totalTokens}'),
                  const Divider(),
                  _buildStatRow(
                    'Coût total',
                    '\$${_geminiStats!.totalCost.toStringAsFixed(4)}',
                    highlight: true,
                  ),
                  _buildStatRow(
                    'Coût moyen',
                    '\$${_geminiStats!.avgCostPerCall.toStringAsFixed(6)}/appel',
                  ),
                  const SizedBox(height: 12),
                  if (_geminiStats!.totalCost > 10.0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Coût élevé! Envisagez de désactiver Gemini.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        // Reset Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _resetStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser les statistiques'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayerStat(String label, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$count (${percentage.toStringAsFixed(1)}%)'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}
