import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/note.dart';
import '../models/tarif.dart';
import '../services/auth_service.dart';
import '../services/gestion_repository.dart';
import '../widgets/decorative_background.dart';
import '../widgets/section_placeholder.dart';
import 'facture_screen.dart';

const _accent = [Color(0xFF1B3B5F), Color(0xFFC9A24B)];

enum _Rubrique { clients, commandes, notes }

/// Consultation en lecture seule des clients/commandes/notes d'un commercial,
/// ouverte depuis GestionCommerciauxScreen — l'admin reste connecté avec son
/// propre compte pendant qu'il regarde (voir GestionRepository.
/// ownerUidPourConsultation et les règles Firestore associées, qui
/// autorisent l'admin à lire mais jamais à écrire pour un autre compte).
class VueCommercialScreen extends StatefulWidget {
  final CompteCommercial compte;

  const VueCommercialScreen({super.key, required this.compte});

  @override
  State<VueCommercialScreen> createState() => _VueCommercialScreenState();
}

class _VueCommercialScreenState extends State<VueCommercialScreen> {
  Tarif _tarif = Tarif.aquajex;
  _Rubrique _rubrique = _Rubrique.clients;

  bool _chargement = true;
  String? _erreur;
  List<Client> _clients = [];
  List<Commande> _commandes = [];
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final repo = GestionRepository(
        _tarif,
        ownerUidPourConsultation: widget.compte.uid,
      );
      final clients = await repo.getClients();
      final commandes = await repo.getCommandes();
      final notes = await repo.getNotes();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _commandes = commandes;
        _notes = notes;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = '$e';
        _chargement = false;
      });
    }
  }

  Client? _clientPour(Commande commande) {
    for (final c in _clients) {
      if (c.id == commande.clientId) return c;
    }
    return null;
  }

  void _changerTarif(Tarif tarif) {
    if (tarif == _tarif) return;
    setState(() => _tarif = tarif);
    _charger();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 24, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.compte.nomComplet.isNotEmpty
                                ? widget.compte.nomComplet
                                : widget.compte.nomUtilisateur,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B3B5F),
                            ),
                          ),
                          Text(
                            '@${widget.compte.nomUtilisateur} · lecture seule',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    for (final t in Tarif.values) ...[
                      _Puce(
                        libelle: t.nom,
                        selectionne: _tarif == t,
                        couleur: t.accentColor,
                        onTap: () => _changerTarif(t),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _OngletRubrique(
                        label: 'Clients (${_clients.length})',
                        selectionne: _rubrique == _Rubrique.clients,
                        onTap: () =>
                            setState(() => _rubrique = _Rubrique.clients),
                      ),
                    ),
                    Expanded(
                      child: _OngletRubrique(
                        label: 'Commandes (${_commandes.length})',
                        selectionne: _rubrique == _Rubrique.commandes,
                        onTap: () =>
                            setState(() => _rubrique = _Rubrique.commandes),
                      ),
                    ),
                    Expanded(
                      child: _OngletRubrique(
                        label: 'Notes (${_notes.length})',
                        selectionne: _rubrique == _Rubrique.notes,
                        onTap: () =>
                            setState(() => _rubrique = _Rubrique.notes),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildCorps()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Impossible de charger : $_erreur',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _charger, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    switch (_rubrique) {
      case _Rubrique.clients:
        return _buildClients();
      case _Rubrique.commandes:
        return _buildCommandes();
      case _Rubrique.notes:
        return _buildNotes();
    }
  }

  Widget _buildClients() {
    if (_clients.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.people_outline,
        titre: 'Aucun client',
        sousTitre:
            'Ce commercial n\'a pas encore ajouté de client\npour ce tarif.',
        accent: _accent,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _clients.length,
      itemBuilder: (context, i) {
        final c = _clients[i];
        return _Carte(
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accent.last.withValues(alpha: 0.15),
                foregroundColor: _accent.last,
                child: Text(c.initiales),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.nomAffichage,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    if (c.telephone != null)
                      Text(
                        c.telephone!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandes() {
    if (_commandes.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.request_quote_outlined,
        titre: 'Aucune commande',
        sousTitre:
            'Ce commercial n\'a pas encore créé de commande\npour ce tarif.',
        accent: _accent,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _commandes.length,
      itemBuilder: (context, i) {
        final commande = _commandes[i];
        return _Carte(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FactureScreen(
                commande: commande,
                client: _clientPour(commande),
                tarif: _tarif,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.last.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: _accent.last,
                  size: 18,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    Text(
                      '${_formatDate(commande.date)} · ${commande.nombreArticles} article${commande.nombreArticles > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: commande.statut.couleur.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        commande.statut.libelle,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: commande.statut.couleur,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatMontant(commande.totalTtc)} DT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _accent.last,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotes() {
    if (_notes.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.sticky_note_2_outlined,
        titre: 'Aucune note',
        sousTitre:
            'Ce commercial n\'a pas encore ajouté de note\npour ce tarif.',
        accent: _accent,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _notes.length,
      itemBuilder: (context, i) {
        final note = _notes[i];
        return _Carte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.clientNom != null) ...[
                Text(
                  note.clientNom!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B5F),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                note.contenu,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(note.date),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Carte extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Carte({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  final String libelle;
  final bool selectionne;
  final Color couleur;
  final VoidCallback onTap;

  const _Puce({
    required this.libelle,
    required this.selectionne,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionne ? couleur : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selectionne
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            libelle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selectionne ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _OngletRubrique extends StatelessWidget {
  final String label;
  final bool selectionne;
  final VoidCallback onTap;

  const _OngletRubrique({
    required this.label,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selectionne ? _accent.last : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
            color: selectionne
                ? _accent.last
                : Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
