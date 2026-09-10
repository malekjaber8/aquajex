import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/tarif.dart';
import '../../widgets/barre_recherche.dart';
import '../../widgets/client_tile.dart';
import '../../widgets/section_placeholder.dart';

class ClientsSection extends StatelessWidget {
  final Tarif tarif;
  final List<Client> clients;
  final ValueChanged<Client> onEdit;
  final ValueChanged<Client> onDelete;
  final VoidCallback onAjouter;
  final String recherche;
  final ValueChanged<String> onRechercheChanged;

  const ClientsSection({
    super.key,
    required this.tarif,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
    required this.onAjouter,
    required this.recherche,
    required this.onRechercheChanged,
  });

  List<Client> get _clientsFiltres {
    final q = recherche.trim().toLowerCase();
    if (q.isEmpty) return clients;
    return clients.where((c) {
      return c.nomComplet.toLowerCase().contains(q) ||
          (c.nomSociete?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;

    if (clients.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.people_outline,
        titre: 'Aucun client pour le moment',
        sousTitre: 'Créez une fiche client pour préparer vos devis\net garder un historique de vos visites.',
        accent: accent,
        actionLabel: 'Créer un client',
        onAction: onAjouter,
      );
    }

    final resultats = _clientsFiltres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: BarreRecherche(
            valeur: recherche,
            accent: accent,
            hintText: 'Rechercher un client (nom, entreprise)…',
            onChanged: onRechercheChanged,
          ),
        ),
        Expanded(
          child: resultats.isEmpty
              ? Center(
                  child: Text(
                    'Aucun client ne correspond à "${recherche.trim()}".',
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
                    final client = resultats[index];
                    return ClientTile(
                      client: client,
                      accent: accent,
                      onEdit: () => onEdit(client),
                      onDelete: () => onDelete(client),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
