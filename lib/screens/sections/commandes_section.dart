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
  });

  Client? _clientPour(Commande commande) {
    for (final c in clients) {
      if (c.id == commande.clientId) return c;
    }
    return null;
  }

  List<Commande> get _commandesFiltrees {
    final q = recherche.trim().toLowerCase();
    if (q.isEmpty) return commandes;
    return commandes.where((c) {
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
        Expanded(
          child: resultats.isEmpty
              ? Center(
                  child: Text(
                    'Aucune facture ne correspond à "${recherche.trim()}".',
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
