import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  bool _rememberTerminal = false;
  bool _obscureKey = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Geometric triangle pattern background
          _buildTriangleBackground(),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 60),
                  
                  // Welcome text
                  const Text(
                    'Welcome\nback',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Subtitle with gold line
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 3,
                        color: const Color(0xFFFFC700),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Access your precision-engineered\nfinancial intelligence dashboard.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: Color(0xFF8B9AAD),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  
                  // Auth card
                  _buildAuthCard(),
                  
                  const SizedBox(height: 32),
                  
                  // Security badge
                  _buildSecurityBadge(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriangleBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: TrianglePatternPainter(),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        // Triangle logo
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 4),
            _buildTriangle(Colors.white),
            const SizedBox(width: 2),
            _buildTriangle(Colors.white),
            const SizedBox(width: 2),
            _buildTriangle(const Color(0xFFFFC700)),
          ],
        ),
        const SizedBox(width: 16),
        const Text(
          'SMARTBANK AI',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTriangle(Color color) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: TrianglePainter(color),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFFFC700),
            width: 4,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Authentication',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'THE KINETIC PRECISION STANDARD',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B9AAD),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Client Identifier
            const Text(
              'CLIENT IDENTIFIER',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B9AAD),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _identifierController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g. AI-98234',
                hintStyle: const TextStyle(color: Color(0xFF5A6B7F)),
                filled: true,
                fillColor: const Color(0xFF0D1B2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Access Key
            const Text(
              'ACCESS KEY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B9AAD),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accessKeyController,
              obscureText: _obscureKey,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '••••••••••••',
                hintStyle: const TextStyle(color: Color(0xFF5A6B7F)),
                filled: true,
                fillColor: const Color(0xFF0D1B2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF8B9AAD),
                  ),
                  onPressed: () {
                    setState(() => _obscureKey = !_obscureKey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Remember terminal + Key Recovery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberTerminal,
                        onChanged: (val) {
                          setState(() => _rememberTerminal = val ?? false);
                        },
                        fillColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return const Color(0xFFFFC700);
                          }
                          return Colors.transparent;
                        }),
                        side: const BorderSide(color: Color(0xFF5A6B7F)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember terminal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF8B9AAD),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Key Recovery',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFC700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Authorize button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC700),
                  foregroundColor: const Color(0xFF0A1628),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF0A1628)),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AUTHORIZE ACCESS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Initialize portfolio button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF5A6B7F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'INITIALIZE NEW PORTFOLIO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF162639),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock,
              color: Color(0xFFFFC700),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'AES-256 ENCRYPTED CONNECTION',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B9AAD),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.login(
        username: _identifierController.text,
        password: _accessKeyController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _accessKeyController.dispose();
    super.dispose();
  }
}

// Custom painter for triangles
class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Background triangle pattern
class TrianglePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw large triangles in background
    final path1 = Path();
    path1.moveTo(size.width * 0.8, 0);
    path1.lineTo(size.width, size.height * 0.3);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.lineTo(size.width * 0.3, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
