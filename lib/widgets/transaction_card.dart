import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String merchantName;
  final String details;
  final String category;
  final String date;
  final double amount;
  final IconData icon;
  final bool isIncome;
  
  const TransactionCard({
    super.key,
    required this.merchantName,
    required this.details,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFC700),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF8B9AAD),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncome 
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isIncome 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF8B9AAD),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Date and amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF8B9AAD),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${isIncome ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isIncome 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFC700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}