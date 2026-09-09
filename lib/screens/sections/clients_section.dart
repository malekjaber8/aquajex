import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/tarif.dart';
import '../../widgets/client_tile.dart';
import '../../widgets/section_placeholder.dart';

class ClientsSection extends StatelessWidget {
  final Tarif tarif;
  final List<Client> clients;
  final ValueChanged<Client> onEdit;
  final ValueChanged<Client> onDelete;
  final VoidCallback onAjouter;

  const ClientsSection({
    super.key,
    required this.tarif,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;

    if (clients.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.people_outline,
        titre: 'Aucun client pour le moment',
        sousTitre:
            'Créez une fiche client pour préparer vos devis\net garder un historique de vos visites.',
        accent: accent,
        actionLabel: 'Créer un client',
        onAction: onAjouter,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return ClientTile(
          client: client,
          accent: accent,
          onEdit: () => onEdit(client),
          onDelete: () => onDelete(client),
        );
      },
    );
  }
}
