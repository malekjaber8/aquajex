import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/commande.dart';
import '../../models/tarif.dart';
import '../../widgets/commande_tile.dart';
import '../../widgets/section_placeholder.dart';
import '../facture_screen.dart';

class CommandesSection extends StatelessWidget {
  final Tarif tarif;
  final List<Commande> commandes;
  final List<Client> clients;
  final ValueChanged<Commande> onEdit;
  final ValueChanged<Commande> onDelete;

  const CommandesSection({
    super.key,
    required this.tarif,
    required this.commandes,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
  });

  Client? _clientPour(Commande commande) {
    for (final c in clients) {
      if (c.id == commande.clientId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;

    if (commandes.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.request_quote_outlined,
        titre: 'Aucune commande pour le moment',
        sousTitre:
            'Ajoutez des articles au panier depuis le catalogue\net assignez-les à un client pour créer une commande.',
        accent: accent,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: commandes.length,
      itemBuilder: (context, index) {
        final commande = commandes[index];
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
        );
      },
    );
  }
}
