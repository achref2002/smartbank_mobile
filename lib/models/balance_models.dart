class ForecastPoint {
  final String date;
  final double predicted;
  final double lower;
  final double upper;
  final String model;

  ForecastPoint({
    required this.date,
    required this.predicted,
    required this.lower,
    required this.upper,
    required this.model,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      date: json['date'] as String,
      predicted: (json['predicted'] as num).toDouble(),
      lower: (json['lower'] as num).toDouble(),
      upper: (json['upper'] as num).toDouble(),
      model: json['model'] as String,
    );
  }
}

class OverdraftRisk {
  final double riskScore;
  final String riskLevel;
  final int? daysUntilOverdraft;
  final double minPredictedBalance;
  final double currentBalance;
  final double pendingRecurring;
  final double realBalance;
  final List<String> actions;
  final int forecastHorizon;

  OverdraftRisk({
    required this.riskScore,
    required this.riskLevel,
    this.daysUntilOverdraft,
    required this.minPredictedBalance,
    required this.currentBalance,
    required this.pendingRecurring,
    required this.realBalance,
    required this.actions,
    required this.forecastHorizon,
  });

  factory OverdraftRisk.fromJson(Map<String, dynamic> json) {
    return OverdraftRisk(
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      daysUntilOverdraft: json['days_until_overdraft'] as int?,
      minPredictedBalance: (json['min_predicted_balance'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      pendingRecurring: (json['pending_recurring'] as num).toDouble(),
      realBalance: (json['real_balance'] as num).toDouble(),
      actions: List<String>.from(json['actions'] as List),
      forecastHorizon: json['forecast_horizon'] as int,
    );
  }

  // Helper methods
  bool get isCritical => riskLevel == 'critical';
  bool get isHigh => riskLevel == 'high';
  bool get isMedium => riskLevel == 'medium';
  bool get isLow => riskLevel == 'low';
}

class BalancePredictionResponse {
  final String accountId;
  final String modelType;
  final List<ForecastPoint> forecasts;
  final OverdraftRisk risk;
  final double? mae;
  final double trainingSeconds;
  final int dataPointsUsed;
  // Metadata added by the forecast endpoint
  final String? generatedAt;
  final String? forecastStart;
  final String? forecastEnd;
  final String? lastDataDate;

  BalancePredictionResponse({
    required this.accountId,
    required this.modelType,
    required this.forecasts,
    required this.risk,
    this.mae,
    required this.trainingSeconds,
    required this.dataPointsUsed,
    this.generatedAt,
    this.forecastStart,
    this.forecastEnd,
    this.lastDataDate,
  });

  /// True when the forecast's target dates are all in the past relative to today.
  bool get isHistorical {
    if (forecastEnd == null) return false;
    try {
      return DateTime.parse(forecastEnd!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  factory BalancePredictionResponse.fromJson(Map<String, dynamic> json) {
    return BalancePredictionResponse(
      accountId:       json['account_id']       as String,
      modelType:       json['model_type']        as String? ?? 'unknown',
      forecasts: (json['forecasts'] as List)
          .map((f) => ForecastPoint.fromJson(f as Map<String, dynamic>))
          .toList(),
      risk: json['risk'] != null
          ? OverdraftRisk.fromJson(json['risk'] as Map<String, dynamic>)
          : OverdraftRisk(riskScore: 0, riskLevel: 'unknown',
              minPredictedBalance: 0, currentBalance: 0,
              pendingRecurring: 0, realBalance: 0,
              actions: [], forecastHorizon: 30),
      mae:              json['mae']              != null ? (json['mae'] as num).toDouble() : null,
      trainingSeconds: (json['training_seconds'] as num?)?.toDouble() ?? 0,
      dataPointsUsed:  (json['data_points_used'] as int?) ?? 0,
      generatedAt:      json['generated_at']     as String?,
      forecastStart:    json['forecast_start']   as String?,
      forecastEnd:      json['forecast_end']     as String?,
      lastDataDate:     json['last_data_date']   as String?,
    );
  }
}

class GeminiStats {
  final int totalCalls;
  final int cacheHits;
  final int cacheMisses;
  final double cacheHitRate;
  final int errors;
  final int totalTokens;
  final double totalCost;
  final double avgCostPerCall;

  GeminiStats({
    required this.totalCalls,
    required this.cacheHits,
    required this.cacheMisses,
    required this.cacheHitRate,
    required this.errors,
    required this.totalTokens,
    required this.totalCost,
    required this.avgCostPerCall,
  });

  factory GeminiStats.fromJson(Map<String, dynamic> json) {
    return GeminiStats(
      totalCalls: json['total_calls'] as int,
      cacheHits: json['cache_hits'] as int,
      cacheMisses: json['cache_misses'] as int,
      cacheHitRate: (json['cache_hit_rate'] as num).toDouble(),
      errors: json['errors'] as int,
      totalTokens: json['total_tokens'] as int,
      totalCost: (json['total_cost'] as num).toDouble(),
      avgCostPerCall: (json['avg_cost_per_call'] as num).toDouble(),
    );
  }
}

class ClassifierStats {
  final int totalClassifications;
  final int layer1Rules;
  final double layer1Percentage;
  final int layer2Embeddings;
  final double layer2Percentage;
  final int layer3MlModel;
  final double layer3Percentage;
  final int layer4Gemini;
  final double layer4Percentage;

  ClassifierStats({
    required this.totalClassifications,
    required this.layer1Rules,
    required this.layer1Percentage,
    required this.layer2Embeddings,
    required this.layer2Percentage,
    required this.layer3MlModel,
    required this.layer3Percentage,
    required this.layer4Gemini,
    required this.layer4Percentage,
  });

  factory ClassifierStats.fromJson(Map<String, dynamic> json) {
    return ClassifierStats(
      totalClassifications: json['total_classifications'] as int,
      layer1Rules: json['layer1_rules'] as int,
      layer1Percentage: (json['layer1_percentage'] as num).toDouble(),
      layer2Embeddings: json['layer2_embeddings'] as int,
      layer2Percentage: (json['layer2_percentage'] as num).toDouble(),
      layer3MlModel: json['layer3_ml_model'] as int,
      layer3Percentage: (json['layer3_percentage'] as num).toDouble(),
      layer4Gemini: json['layer4_gemini'] as int,
      layer4Percentage: (json['layer4_percentage'] as num).toDouble(),
    );
  }
}
