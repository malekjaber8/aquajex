import 'package:flutter/material.dart';

import '../models/mode_prix.dart';
import '../services/catalogue_repository.dart';
import 'statut_articles_view.dart';

enum _FiltreStock { tous, enStock, rupture }

/// Rubrique "Gestion de stock" (mélange des deux catalogues), qui liste les
/// articles filtrés par disponibilité — affichée à l'identique depuis la
/// page d'accueil et depuis chaque catalogue ouvert, comme Promotion/
/// Nouveauté.
class GestionStockView extends StatefulWidget {
  final List<ArticleAvecTarif> articles;
  final ModePrix modePrix;
  final ValueChanged<ArticleAvecTarif> onTapArticle;

  const GestionStockView({
    super.key,
    required this.articles,
    required this.modePrix,
    required this.onTapArticle,
  });

  @override
  State<GestionStockView> createState() => _GestionStockViewState();
}

class _GestionStockViewState extends State<GestionStockView> {
  _FiltreStock _filtre = _FiltreStock.tous;

  List<ArticleAvecTarif> get _articlesFiltres {
    switch (_filtre) {
      case _FiltreStock.tous:
        return widget.articles;
      case _FiltreStock.enStock:
        return widget.articles.where((a) => a.article.disponible).toList();
      case _FiltreStock.rupture:
        return widget.articles.where((a) => !a.article.disponible).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultats = _articlesFiltres;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 4),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_outlined,
                color: Color(0xFF1B3B5F),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Gestion de stock',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B3B5F),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              _FiltreChip(
                label: 'Tous',
                selectionne: _filtre == _FiltreStock.tous,
                onTap: () => setState(() => _filtre = _FiltreStock.tous),
              ),
              const SizedBox(width: 8),
              _FiltreChip(
                label: 'En stock',
                couleur: const Color(0xFF2FAE60),
                selectionne: _filtre == _FiltreStock.enStock,
                onTap: () => setState(() => _filtre = _FiltreStock.enStock),
              ),
              const SizedBox(width: 8),
              _FiltreChip(
                label: 'Rupture',
                couleur: Colors.redAccent,
                selectionne: _filtre == _FiltreStock.rupture,
                onTap: () => setState(() => _filtre = _FiltreStock.rupture),
              ),
            ],
          ),
        ),
        Expanded(
          child: resultats.isEmpty
              ? Center(
                  child: Text(
                    'Aucun article ne correspond à ce filtre',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: resultats.length,
                  itemBuilder: (context, i) => CarteArticleMixte(
                    data: resultats[i],
                    modePrix: widget.modePrix,
                    onTap: () => widget.onTapArticle(resultats[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool selectionne;
  final Color couleur;
  final VoidCallback onTap;

  const _FiltreChip({
    required this.label,
    required this.selectionne,
    required this.onTap,
    this.couleur = const Color(0xFF1B3B5F),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionne ? couleur : Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selectionne ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
