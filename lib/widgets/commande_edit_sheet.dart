import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/mode_prix.dart';

/// Ouvre l'édition d'une commande existante : quantités, suppression de
/// lignes, ajout d'articles, changement de client. Retourne true si la
/// commande a été enregistrée.
Future<bool?> afficherEditionCommande(
  BuildContext context, {
  required Commande commande,
  required List<Color> accent,
  required ModePrix modePrix,
  required List<Article> articlesDisponibles,
  required List<Client> Function() clientsActuels,
  required Future<Client?> Function() onNouveauClient,
  required Future<void> Function(
    String clientId,
    String clientNom,
    List<LigneCommande> lignes,
    String? note,
  )
  onEnregistrer,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CommandeEditSheet(
      commande: commande,
      accent: accent,
      modePrix: modePrix,
      articlesDisponibles: articlesDisponibles,
      clientsActuels: clientsActuels,
      onNouveauClient: onNouveauClient,
      onEnregistrer: onEnregistrer,
    ),
  );
}

class _CommandeEditSheet extends StatefulWidget {
  final Commande commande;
  final List<Color> accent;
  final ModePrix modePrix;
  final List<Article> articlesDisponibles;
  final List<Client> Function() clientsActuels;
  final Future<Client?> Function() onNouveauClient;
  final Future<void> Function(
    String clientId,
    String clientNom,
    List<LigneCommande> lignes,
    String? note,
  )
  onEnregistrer;

  const _CommandeEditSheet({
    required this.commande,
    required this.accent,
    required this.modePrix,
    required this.articlesDisponibles,
    required this.clientsActuels,
    required this.onNouveauClient,
    required this.onEnregistrer,
  });

  @override
  State<_CommandeEditSheet> createState() => _CommandeEditSheetState();
}

class _CommandeEditSheetState extends State<_CommandeEditSheet> {
  final List<LigneCommande> _lignes = [];
  late final _noteCtrl = TextEditingController(text: widget.commande.note);
  late String _clientId = widget.commande.clientId;
  late String _clientNom = widget.commande.clientNom;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _lignes.addAll(widget.commande.lignes);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _total => _lignes.fold(0, (s, l) => s + l.total);

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
      final ligne = _lignes[index];
      final nouvelleQte = ligne.quantite + delta;
      if (nouvelleQte <= 0) {
        _lignes.removeAt(index);
      } else {
        _lignes[index] = ligne.copyWith(quantite: nouvelleQte);
      }
    });
  }

  void _supprimerLigne(int index) {
    setState(() => _lignes.removeAt(index));
  }

  Future<void> _changerClient() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientPickerSheet(
        accent: widget.accent,
        clients: widget.clientsActuels(),
        onNouveauClient: widget.onNouveauClient,
      ),
    );
    if (client == null || !mounted) return;
    setState(() {
      _clientId = client.id;
      _clientNom = client.nomComplet;
    });
  }

  Future<void> _ajouterArticle() async {
    final article = await showModalBottomSheet<Article>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArticlePickerSheet(
        accent: widget.accent,
        articles: widget.articlesDisponibles,
      ),
    );
    if (article == null || !mounted) return;
    final prix = widget.modePrix == ModePrix.detail
        ? article.prixDetail
        : article.prixGros;
    setState(() {
      final index = _lignes.indexWhere((l) => l.articleId == article.id);
      if (index != -1) {
        _lignes[index] = _lignes[index].copyWith(
          quantite: _lignes[index].quantite + 1,
        );
      } else {
        _lignes.add(
          LigneCommande(
            articleId: article.id,
            designation: article.designation,
            prixUnitaire: prix,
            quantite: 1,
          ),
        );
      }
    });
  }

  Future<void> _enregistrer() async {
    if (_lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un article')),
      );
      return;
    }
    setState(() => _enCours = true);
    final note = _noteCtrl.text.trim();
    await widget.onEnregistrer(
      _clientId,
      _clientNom,
      _lignes,
      note.isEmpty ? null : note,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Color(0xFF1B3B5F)),
                  const SizedBox(width: 10),
                  const Text(
                    'Modifier la commande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3B5F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: accent.last.withValues(alpha: 0.15),
                      foregroundColor: accent.last,
                      child: Text(
                        _clientNom.isNotEmpty
                            ? _clientNom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _clientNom,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B3B5F),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _changerClient,
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Articles',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _ajouterArticle,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter un article'),
                    style: TextButton.styleFrom(foregroundColor: accent.last),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _lignes.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun article dans cette commande.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: _lignes.length,
                      itemBuilder: (context, index) {
                        final ligne = _lignes[index];
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
                                onPressed: () => _supprimerLigne(index),
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Note (facultative)',
                  filled: true,
                  fillColor: const Color(0xFFF3F5F8),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
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
                          style: TextStyle(fontSize: 14, color: Colors.black54),
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
                            onTap: _enCours ? null : _enregistrer,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: _enCours
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Enregistrer les modifications',
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
                      'Changer de client',
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

class _ArticlePickerSheet extends StatefulWidget {
  final List<Color> accent;
  final List<Article> articles;

  const _ArticlePickerSheet({required this.accent, required this.articles});

  @override
  State<_ArticlePickerSheet> createState() => _ArticlePickerSheetState();
}

class _ArticlePickerSheetState extends State<_ArticlePickerSheet> {
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
    final articlesFiltres = widget.articles.where((a) {
      if (_recherche.isEmpty) return true;
      final q = _recherche.toLowerCase();
      return a.designation.toLowerCase().contains(q) ||
          a.categorie.toLowerCase().contains(q) ||
          (a.codeArticle?.toLowerCase().contains(q) ?? false);
    }).toList();

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ajouter un article',
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
                  hintText: 'Rechercher un article…',
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
            Expanded(
              child: articlesFiltres.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun article trouvé',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: articlesFiltres.length,
                      itemBuilder: (context, index) {
                        final article = articlesFiltres[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: accent.last.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: accent.last,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            article.designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(article.categorie),
                          onTap: () => Navigator.of(context).pop(article),
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
