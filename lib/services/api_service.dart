import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartbank_mobile/models/balance_models.dart';

class ApiService {
  // ⚠️ FOR BROWSER: Use localhost
  // ⚠️ FOR ANDROID EMULATOR: Use 10.0.2.2
  // ⚠️ FOR REAL DEVICE: Use your PC's IP address (like 192.168.1.100)
  
  //static const String baseUrl = 'http://localhost:8000';
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  final storage = const FlutterSecureStorage();
  
  // ───────────────────────────────────────────────────────────────────────────
  // Token Management
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }
  
  Future<void> saveToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }
  
  Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }
  
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // Authentication
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }
  
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Connection timed out. Check server address.'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }
  
  Future<void> logout() async {
    await deleteToken();
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to get user info');
    }
  }
  
  Future<List<dynamic>> getMyAccounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/accounts'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['accounts'];
    } else {
      throw Exception('Failed to get accounts');
    }
  }

  /// Link logged-in user to an existing account (account must exist in DB).
  Future<Map<String, dynamic>> linkAccount(String accountId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/accounts/link'),
      headers: await getHeaders(),
      body: jsonEncode({'account_id': accountId}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to link account');
  }

  /// Create a new account and immediately link it to the logged-in user.
  Future<Map<String, dynamic>> createAndLinkAccount(String accountId, {String profile = 'personal'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/accounts/create'),
      headers: await getHeaders(),
      body: jsonEncode({'account_id': accountId, 'profile': profile}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to create account');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Classification
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> classify({
    required String description,
    required double amount,
    String? merchantName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classify'),
      headers: await getHeaders(),
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'merchant_name': merchantName,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Classification failed');
    }
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // Recurring Charges
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<List<dynamic>> getRecurringCharges(String accountId, {bool activeOnly = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId/recurring?active_only=$activeOnly'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get recurring charges');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Transactions
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getTransactions(String accountId, {int limit = 100}) async {
    final url = Uri.parse('$baseUrl/accounts/$accountId/transactions?limit=$limit');

    try {
      final response = await http.get(
        url,
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        // Helpful debug output when testing against different backends
        // ignore: avoid_print
        print('getTransactions: status=${response.statusCode} body=${response.body}');

        final data = jsonDecode(response.body);
        if (data is List) return data;

        if (data is Map) {
          // Common keys used by various backends
          if (data['transactions'] != null && data['transactions'] is List) return data['transactions'];
          if (data['results'] != null && data['results'] is List) return data['results'];
          if (data['data'] != null && data['data'] is List) return data['data'];
          if (data['items'] != null && data['items'] is List) return data['items'];

          // As a last resort, return the first list value found in the map
          for (final v in data.values) {
            if (v is List) return v;
          }
        }

        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - please re-authenticate');
      } else if (response.statusCode == 404) {
        // Primary endpoint not found. Try a set of common alternate routes.
        // ignore: avoid_print
        print('getTransactions: primary endpoint returned 404, trying fallbacks');

        final candidates = [
          '/accounts/$accountId/ledger',
          '/accounts/$accountId/operations',
          '/accounts/$accountId/payments',
          '/transactions?account_id=$accountId&limit=$limit',
          '/accounts/$accountId/transactions/list',
        ];

        for (final path in candidates) {
          final tryUrl = Uri.parse('$baseUrl$path');
          // ignore: avoid_print
          print('getTransactions: trying $tryUrl');
          final r = await http.get(tryUrl, headers: await getHeaders());
          // ignore: avoid_print
          print('getTransactions: tried $tryUrl status=${r.statusCode}');
          if (r.statusCode == 200) {
            final d = jsonDecode(r.body);
            if (d is List) return d;
            if (d is Map) {
              if (d['transactions'] != null && d['transactions'] is List) return d['transactions'];
              if (d['results'] != null && d['results'] is List) return d['results'];
              if (d['data'] != null && d['data'] is List) return d['data'];
              for (final v in d.values) {
                if (v is List) return v;
              }
            }
          }
        }

        throw Exception('Transactions endpoint not found (404)');
      } else {
        throw Exception('Failed to fetch transactions: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('getTransactions: error $e');
      throw Exception('Network error: $e');
    }
  }

  
  // ───────────────────────────────────────────────────────────────────────────
  // Real Balance
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> getRealBalance(String accountId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId/real-balance'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get real balance');
    }
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // Alerts
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<List<dynamic>> getAlerts(String accountId, {bool unresolvedOnly = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId/alerts?unresolved_only=$unresolvedOnly'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get alerts');
    }
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // Health Check
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/healthz'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Health check failed');
    }
  }

  // =========================================================================
  // BALANCE PREDICTION APIs (NEW)
  // =========================================================================

  /// Train models and predict balance for next N days
  /// Takes 10-30 seconds to complete
  Future<BalancePredictionResponse> predictBalance({
    required String accountId,
    int horizon = 30,
    int salaryDay = 25,
  }) async {
    final url = Uri.parse(
      '$baseUrl/accounts/$accountId/balance/predict?horizon=$horizon&salary_day=$salaryDay',
    );

    try {
      final response = await http.post(
        url,
        headers: await getHeaders(includeAuth: true),
      ).timeout(
        const Duration(seconds: 180),
        onTimeout: () => throw Exception('Forecast timed out — server is still training. Try again in a moment.'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BalancePredictionResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied to this account');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid request');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Balance prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Forecast timed out')) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// Get cached balance forecast (instant, no training)
  Future<BalancePredictionResponse> getBalanceForecast({
    required String accountId,
  }) async {
    final url = Uri.parse('$baseUrl/accounts/$accountId/balance/forecast');

    try {
      final response = await http.get(
        url,
        headers: await getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BalancePredictionResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('No forecast available. Train model first.');
      } else {
        throw Exception('Failed to fetch forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get latest overdraft risk assessment
  Future<OverdraftRisk> getOverdraftRisk({
    required String accountId,
  }) async {
    final url = Uri.parse('$baseUrl/accounts/$accountId/balance/risk');

    try {
      final response = await http.get(
        url,
        headers: await getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OverdraftRisk.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('No risk assessment available. Train model first.');
      } else {
        throw Exception('Failed to fetch risk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =========================================================================
  // ANALYZE — full pipeline trigger
  // =========================================================================

  /// Run full AI analysis: recurring detection + forecast + risk + alerts.
  /// Call this once for a fresh account, or to refresh data.
  Future<Map<String, dynamic>> analyzeAccount({
    required String accountId,
    int horizon = 30,
    int salaryDay = 25,
  }) async {
    final url = Uri.parse(
      '$baseUrl/accounts/$accountId/analyze?horizon=$horizon&salary_day=$salaryDay',
    );
    try {
      final response = await http.post(
        url,
        headers: await getHeaders(includeAuth: true),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['detail'] ?? 'Analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =========================================================================
  // GEMINI MONITORING APIs (NEW)
  // =========================================================================

  /// Get classifier pipeline statistics
  Future<ClassifierStats> getClassifierStats() async {
    final url = Uri.parse('$baseUrl/classifier/stats');

    try {
      final response = await http.get(
        url,
        headers: await getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClassifierStats.fromJson(data);
      } else {
        throw Exception('Failed to fetch classifier stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get Gemini API usage statistics
  Future<GeminiStats> getGeminiStats() async {
    final url = Uri.parse('$baseUrl/classifier/gemini-stats');

    try {
      final response = await http.get(
        url,
        headers: await getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GeminiStats.fromJson(data);
      } else {
        throw Exception('Failed to fetch Gemini stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Reset classifier statistics
  Future<void> resetClassifierStats() async {
    final url = Uri.parse('$baseUrl/classifier/reset-stats');

    try {
      final response = await http.post(
        url,
        headers: await getHeaders(includeAuth: true),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getBacktest({
    required String accountId,
    int testDays = 14,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/accounts/$accountId/balance/backtest?test_days=$testDays'),
        headers: await getHeaders(),
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      throw Exception('Backtest failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Module 1 — Optimize: get saving recommendations for fixed charges.
  Future<Map<String, dynamic>> getOptimizeRecommendations(String accountId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId/optimize'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 403) {
      throw Exception('Accès refusé à ce compte');
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Erreur optimize');
    }
  }
}