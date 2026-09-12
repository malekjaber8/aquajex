import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/commande.dart';
import '../../models/tarif.dart';
import '../../widgets/barre_recherche.dart';
import '../../widgets/commande_tile.dart';
import '../../widgets/section_placeholder.dart';
import '../facture_screen.dart';

class CommandesSection extends StatelessWidget {
  final Tarif tarif;
  final List<Commande> commandes;
  final List<Client> clients;
  final ValueChanged<Commande> onEdit;
  final ValueChanged<Commande> onDelete;
  final void Function(Commande commande, StatutCommande statut) onChangerStatut;
  final String recherche;
  final ValueChanged<String> onRechercheChanged;

  /// null = "Tous" (aucun filtre par statut).
  final StatutCommande? filtreStatut;
  final ValueChanged<StatutCommande?> onFiltreStatutChanged;

  const CommandesSection({
    super.key,
    required this.tarif,
    required this.commandes,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
    required this.onChangerStatut,
    required this.recherche,
    required this.onRechercheChanged,
    required this.filtreStatut,
    required this.onFiltreStatutChanged,
  });

  Client? _clientPour(Commande commande) {
    for (final c in clients) {
      if (c.id == commande.clientId) return c;
    }
    return null;
  }

  List<Commande> get _commandesFiltrees {
    final q = recherche.trim().toLowerCase();
    return commandes.where((c) {
      if (filtreStatut != null && c.statut != filtreStatut) return false;
      if (q.isEmpty) return true;
      return c.id.toLowerCase().contains(q) ||
          c.clientNom.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;

    if (commandes.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.request_quote_outlined,
        titre: 'Aucune commande pour le moment',
        sousTitre: 'Ajoutez des articles au panier depuis le catalogue\net assignez-les à un client pour créer une commande.',
        accent: accent,
      );
    }

    final resultats = _commandesFiltrees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: BarreRecherche(
            valeur: recherche,
            accent: accent,
            hintText: 'Rechercher une facture (n°, nom du client)…',
            onChanged: onRechercheChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: _FiltreStatutCommandeBar(
            accent: accent,
            valeur: filtreStatut,
            onChanged: onFiltreStatutChanged,
          ),
        ),
        Expanded(
          child: resultats.isEmpty
              ? Center(
                  child: Text(
                    recherche.trim().isNotEmpty
                        ? 'Aucune facture ne correspond à "${recherche.trim()}".'
                        : 'Aucune facture ${filtreStatut!.libelle.toLowerCase()} pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  itemCount: resultats.length,
                  itemBuilder: (context, index) {
                    final commande = resultats[index];
                    return CommandeTile(
                      commande: commande,
                      accent: accent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FactureScreen(
                            commande: commande,
                            client: _clientPour(commande),
                            tarif: tarif,
                            onModifier: () => onEdit(commande),
                          ),
                        ),
                      ),
                      onEdit: () => onEdit(commande),
                      onDelete: () => onDelete(commande),
                      onChangerStatut: (statut) =>
                          onChangerStatut(commande, statut),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FiltreStatutCommandeBar extends StatelessWidget {
  final List<Color> accent;
  final StatutCommande? valeur;
  final ValueChanged<StatutCommande?> onChanged;

  const _FiltreStatutCommandeBar({
    required this.accent,
    required this.valeur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _puce(null, 'Tous', accent.last),
          for (final statut in StatutCommande.values) ...[
            const SizedBox(width: 8),
            _puce(statut, statut.libelle, statut.couleur),
          ],
        ],
      ),
    );
  }

  Widget _puce(StatutCommande? statut, String libelle, Color couleur) {
    final selectionne = valeur == statut;
    return Material(
      color: selectionne ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onChanged(selectionne ? null : statut),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selectionne ? couleur : null,
            border: Border.all(
              color: selectionne
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statut != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectionne ? Colors.white : couleur,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                libelle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selectionne ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
