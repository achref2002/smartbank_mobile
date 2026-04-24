import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final String title;
  final String message;
  final String severity; // CRITICAL, WARNING, INFO
  final String? location;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  
  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.severity,
    this.location,
    this.action,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == 'CRITICAL';
    final borderColor = isCritical ? const Color(0xFFFF5252) : const Color(0xFFFFC700);
    final bgColor = const Color(0xFF162639);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical ? Icons.warning : Icons.info,
                      size: 12,
                      color: borderColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PRIORITY $severity',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: borderColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              children: [
                TextSpan(text: title),
                if (location != null)
                  TextSpan(
                    text: ' $location',
                    style: const TextStyle(
                      color: Color(0xFFFFC700),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Message
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF8B9AAD),
              height: 1.5,
            ),
          ),
          
          if (action != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC700),
                      foregroundColor: const Color(0xFF0A1628),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          action!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B9AAD),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Life event card (gold background)
class LifeEventCard extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final VoidCallback? onAction;
  
  const LifeEventCard({
    super.key,
    required this.title,
    required this.message,
    required this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.celebration,
            color: Color(0xFF0A1628),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1628),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF5A6B7F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1628),
              foregroundColor: const Color(0xFFFFC700),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}