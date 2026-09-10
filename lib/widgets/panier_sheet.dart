import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/commande.dart';

/// Affiche le panier en cours. Retourne le client choisi si l'utilisateur a
/// demandé à passer à l'étape suivante (récapitulatif) — le panier n'est pas
/// vidé ici, la commande n'est créée qu'après confirmation du récapitulatif.
Future<Client?> afficherPanier(
  BuildContext context, {
  required List<LigneCommande> lignes,
  required List<Color> accent,
  required Future<Client?> Function() onNouveauClient,
  required List<Client> Function() clientsActuels,
}) {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PanierSheet(
      lignes: lignes,
      accent: accent,
      onNouveauClient: onNouveauClient,
      clientsActuels: clientsActuels,
    ),
  );
}

class _PanierSheet extends StatefulWidget {
  final List<LigneCommande> lignes;
  final List<Color> accent;
  final Future<Client?> Function() onNouveauClient;
  final List<Client> Function() clientsActuels;

  const _PanierSheet({
    required this.lignes,
    required this.accent,
    required this.onNouveauClient,
    required this.clientsActuels,
  });

  @override
  State<_PanierSheet> createState() => _PanierSheetState();
}

class _PanierSheetState extends State<_PanierSheet> {
  double get _total => widget.lignes.fold(0, (s, l) => s + l.total);

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

  void _modifierQuantite(int index, int delta) {
    setState(() {
      final ligne = widget.lignes[index];
      final nouvelleQte = ligne.quantite + delta;
      if (nouvelleQte <= 0) {
        widget.lignes.removeAt(index);
      } else {
        widget.lignes[index] = ligne.copyWith(quantite: nouvelleQte);
      }
    });
  }

  void _supprimer(int index) {
    setState(() => widget.lignes.removeAt(index));
  }

  Future<void> _assignerClient() async {
    final accent = widget.accent;
    final client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientPickerSheet(
        accent: accent,
        clients: widget.clientsActuels(),
        onNouveauClient: widget.onNouveauClient,
      ),
    );
    if (client == null || !mounted) return;
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF1B3B5F),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Panier',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3B5F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.lignes.isEmpty
                  ? Center(
                      child: Text(
                        'Le panier est vide.\nAjoutez des articles depuis le catalogue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: widget.lignes.length,
                      itemBuilder: (context, index) {
                        final ligne = widget.lignes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ligne.designation,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B3B5F),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatMontant(ligne.prixUnitaire)} DT / unité',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StepperQuantite(
                                quantite: ligne.quantite,
                                accent: accent,
                                onMoins: () => _modifierQuantite(index, -1),
                                onPlus: () => _modifierQuantite(index, 1),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 74,
                                child: Text(
                                  '${_formatMontant(ligne.total)} DT',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: accent.last,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _supprimer(index),
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (widget.lignes.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${_formatMontant(_total)} DT',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: accent.last,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: accent),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _assignerClient,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  'Assigner à un client',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepperQuantite extends StatelessWidget {
  final int quantite;
  final List<Color> accent;
  final VoidCallback onMoins;
  final VoidCallback onPlus;

  const _StepperQuantite({
    required this.quantite,
    required this.accent,
    required this.onMoins,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _boutonStepper(Icons.remove, onMoins),
          SizedBox(
            width: 26,
            child: Text(
              '$quantite',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3B5F),
              ),
            ),
          ),
          _boutonStepper(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _boutonStepper(IconData icon, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: const Color(0xFF1B3B5F)),
      ),
    );
  }
}

class _ClientPickerSheet extends StatefulWidget {
  final List<Color> accent;
  final List<Client> clients;
  final Future<Client?> Function() onNouveauClient;

  const _ClientPickerSheet({
    required this.accent,
    required this.clients,
    required this.onNouveauClient,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _rechercheCtrl = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final clientsFiltres = widget.clients.where((c) {
      if (_recherche.isEmpty) return true;
      final q = _recherche.toLowerCase();
      return c.nomComplet.toLowerCase().contains(q) ||
          (c.nomSociete?.toLowerCase().contains(q) ?? false);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Assigner à un client',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _rechercheCtrl,
                onChanged: (v) => setState(() => _recherche = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un client…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF3F5F8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final client = await widget.onNouveauClient();
                    if (client != null && context.mounted) {
                      Navigator.of(context).pop(client);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent.last,
                    side: BorderSide(color: accent.last.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Nouveau client'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: clientsFiltres.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun client trouvé',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: clientsFiltres.length,
                      itemBuilder: (context, index) {
                        final client = clientsFiltres[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: accent.last.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: accent.last,
                            child: Text(
                              client.prenom.isNotEmpty
                                  ? client.prenom[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            client.nomComplet,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: client.nomSociete != null
                              ? Text(client.nomSociete!)
                              : null,
                          onTap: () => Navigator.of(context).pop(client),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
