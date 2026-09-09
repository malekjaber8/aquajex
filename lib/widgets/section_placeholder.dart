import 'package:flutter/material.dart';

class SectionPlaceholder extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String sousTitre;
  final List<Color> accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionPlaceholder({
    super.key,
    required this.icon,
    required this.titre,
    required this.sousTitre,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.last.withValues(alpha: 0.14),
                  accent.last.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Icon(icon, size: 40, color: accent.last),
          ),
          const SizedBox(height: 20),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3B5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sousTitre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: accent),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
