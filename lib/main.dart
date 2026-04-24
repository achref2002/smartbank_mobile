import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SmartBankApp());
}

class SmartBankApp extends StatelessWidget {
  const SmartBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBank AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use design system colors
        primaryColor: const Color(0xFFFFC700),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC700),
          secondary: Color(0xFFA8C9F6),
          surface: Color(0xFF162639),
          background: Color(0xFF0A1628),
        ),
        
        fontFamily: 'Inter',
        
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}