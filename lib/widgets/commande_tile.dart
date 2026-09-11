import 'package:flutter/material.dart';

import '../models/commande.dart';

class CommandeTile extends StatelessWidget {
  final Commande commande;
  final List<Color> accent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<StatutCommande>? onChangerStatut;

  const CommandeTile({
    super.key,
    required this.commande,
    required this.accent,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onChangerStatut,
  });

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(3).split('.');
    final chiffres = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(chiffres[i]);
    }
    return '${buffer.toString()},${parts[1]}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.last.withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: accent.last,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commande.clientNom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B3B5F),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${_formatDate(commande.date)} · ${commande.nombreArticles} article${commande.nombreArticles > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      _StatutBadge(
                        statut: commande.statut,
                        onChanger: onChangerStatut,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatMontant(commande.totalTtc)} DT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent.last,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: const Color(0xFF1B3B5F),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 19),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge coloré affichant le statut de la commande, tapable pour le
/// changer (en attente / confirmée / livrée) sans passer par l'écran
/// d'édition complet.
class _StatutBadge extends StatelessWidget {
  final StatutCommande statut;
  final ValueChanged<StatutCommande>? onChanger;

  const _StatutBadge({required this.statut, this.onChanger});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StatutCommande>(
      initialValue: statut,
      tooltip: 'Changer le statut',
      onSelected: onChanger,
      itemBuilder: (context) => [
        for (final s in StatutCommande.values)
          PopupMenuItem(
            value: s,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.couleur,
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.libelle),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statut.couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statut.couleur,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statut.libelle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statut.couleur,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 13, color: statut.couleur),
          ],
        ),
      ),
    );
  }
}
