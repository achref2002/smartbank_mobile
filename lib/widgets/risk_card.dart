import 'package:flutter/material.dart';
import '../models/balance_models.dart';

class RiskCard extends StatelessWidget {
  final OverdraftRisk risk;

  const RiskCard({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_riskIcon(), color: riskColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERDRAFT RISK',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B9AAD),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _riskLabel().toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Risk score pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(risk.riskScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF213A59), height: 1),
          const SizedBox(height: 16),

          // Balance details
          Row(
            children: [
              Expanded(
                child: _balanceItem(
                  'Current Balance',
                  '${risk.currentBalance.toStringAsFixed(2)} €',
                  const Color(0xFFD3E3FF),
                ),
              ),
              Expanded(
                child: _balanceItem(
                  'Pending Charges',
                  '−${risk.pendingRecurring.toStringAsFixed(2)} €',
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _balanceItem(
                  'Real Balance',
                  '${risk.realBalance.toStringAsFixed(2)} €',
                  risk.realBalance < 0
                      ? const Color(0xFFFFB4AB)
                      : const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _balanceItem(
                  'Min Forecast',
                  '${risk.minPredictedBalance.toStringAsFixed(2)} €',
                  risk.minPredictedBalance < 0
                      ? const Color(0xFFFFB4AB)
                      : const Color(0xFF8B9AAD),
                ),
              ),
            ],
          ),

          // Overdraft warning
          if (risk.daysUntilOverdraft != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB4AB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB4AB).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFFFB4AB), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Potential overdraft in ${risk.daysUntilOverdraft} day${risk.daysUntilOverdraft == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFB4AB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF8B9AAD),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _riskColor() {
    switch (risk.riskLevel) {
      case 'critical':
        return const Color(0xFFFFB4AB);
      case 'high':
        return const Color(0xFFFF9800);
      case 'medium':
        return const Color(0xFFFFC700);
      case 'low':
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _riskIcon() {
    switch (risk.riskLevel) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
      default:
        return Icons.check_circle;
    }
  }

  String _riskLabel() {
    switch (risk.riskLevel) {
      case 'critical':
        return 'Critical Risk';
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      case 'low':
      default:
        return 'Low Risk';
    }
  }
}
