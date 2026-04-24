class AppConstants {
  // App Info
  static const String appName = 'FOCUS';
  static const String appFullName = 'FOCUS Financial Intelligence';
  static const String appTagline = 'Access your precision-engineered\nfinancial intelligence dashboard.';
  
  // Logo path - Add your logo to assets/images/
  static const String logoPath = 'assets/images/focus_logo.png';
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  
  // Feature Flags
  static const bool enableCharts = true;
  static const bool enablePredictions = true;
  static const bool enableAlerts = true;
  
  // UI Constants
  static const double bottomNavHeight = 65.0;
  static const double appBarHeight = 60.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
