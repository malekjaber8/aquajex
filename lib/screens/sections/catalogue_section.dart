import 'package:flutter/material.dart';
import '../../models/article.dart';
import '../../models/mode_prix.dart';
import '../../models/tarif.dart';
import '../../widgets/article_card.dart';
import '../../widgets/article_detail_dialog.dart';
import '../../widgets/famille_card.dart';

class CatalogueSection extends StatelessWidget {
  final Tarif tarif;
  final ModePrix modePrix;
  final List<Article> articles;
  final List<String> familles;
  final String? familleSelectionnee;
  final ValueChanged<String?> onFamilleSelectionnee;
  final ValueChanged<Article> onEdit;
  final ValueChanged<Article> onDelete;
  final ValueChanged<String> onEditFamille;
  final ValueChanged<String> onDeleteFamille;
  final ValueChanged<Article> onAjouterPanier;
  final String recherche;
  final ValueChanged<String> onRechercheChanged;

  /// null = "Tous" (catalogue normal, par famille). Promo/nouveauté sont
  /// des filtres transversaux qui affichent les articles concernés de
  /// toutes les familles, comme la recherche.
  final StatutArticle? filtreStatut;
  final ValueChanged<StatutArticle?> onFiltreStatutChanged;

  /// Seul l'admin (PC) peut modifier le catalogue. Le commercial
  /// (tablette) le consulte en lecture seule.
  final bool isAdmin;

  const CatalogueSection({
    super.key,
    required this.tarif,
    required this.modePrix,
    required this.articles,
    required this.familles,
    required this.familleSelectionnee,
    required this.onFamilleSelectionnee,
    required this.onEdit,
    required this.onDelete,
    required this.onEditFamille,
    required this.onDeleteFamille,
    required this.onAjouterPanier,
    required this.recherche,
    required this.onRechercheChanged,
    required this.filtreStatut,
    required this.onFiltreStatutChanged,
    required this.isAdmin,
  });

  int _nombreArticlesPourFamille(String famille) =>
      articles.where((a) => a.categorie == famille).length;

  List<Article> get _articlesDeLaFamille =>
      articles.where((a) => a.categorie == familleSelectionnee).toList();

  /// Nombre de colonnes + ratio largeur/hauteur des cartes article, calculés
  /// à partir de la largeur disponible : sur téléphone (écroit), une seule
  /// carte par ligne pour une meilleure présentation au client, mais sans
  /// dépasser [largeurCarteMax] pour ne pas devenir démesurée.
  ({int colonnes, double ratio, double largeurCarteMax}) _grilleArticles(
      double largeur) {
    final colonnes = largeur > 1200
        ? 5
        : largeur > 900
            ? 4
            : largeur > 700
                ? 3
                : largeur > 480
                    ? 2
                    : 1;
    const padding = 24.0;
    const espacement = 20.0;
    final largeurCellule =
        (largeur - padding * 2 - espacement * (colonnes - 1)) / colonnes;
    const largeurCarteMaxUnique = 300.0;
    final largeurCarte = colonnes == 1
        ? largeurCellule.clamp(0, largeurCarteMaxUnique).toDouble()
        : largeurCellule;
    // Image carrée (AspectRatio 1) + bloc infos (catégorie/titre/prix) en
    // dessous, d'une hauteur à peu près fixe quelle que soit la largeur.
    const hauteurInfos = 140.0;
    final ratio = largeurCellule / (largeurCarte + hauteurInfos);
    return (
      colonnes: colonnes,
      ratio: ratio.clamp(0.35, 1.4),
      largeurCarteMax: colonnes == 1 ? largeurCarteMaxUnique : double.infinity,
    );
  }

  List<Article> get _articlesFiltres {
    final q = recherche.trim().toLowerCase();
    return articles.where((a) {
      if (filtreStatut != null && a.statut != filtreStatut) return false;
      if (q.isEmpty) return true;
      return a.designation.toLowerCase().contains(q) ||
          a.categorie.toLowerCase().contains(q) ||
          (a.codeArticle?.toLowerCase().contains(q) ?? false) ||
          (a.codeBarre?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String _libelleResultats(int total) {
    final pluriel = total > 1 ? 's' : '';
    if (recherche.trim().isNotEmpty && filtreStatut != null) {
      return '$total résultat$pluriel en ${filtreStatut!.libelle.toLowerCase()}';
    }
    if (filtreStatut != null) {
      return '$total article$pluriel en ${filtreStatut!.libelle.toLowerCase()}';
    }
    return '$total résultat$pluriel';
  }

  @override
  Widget build(BuildContext context) {
    final filtreActif = recherche.trim().isNotEmpty || filtreStatut != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: _BarreRecherche(
            valeur: recherche,
            accent: tarif.accentGradient,
            onChanged: onRechercheChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: _FiltreStatutBar(
            accent: tarif.accentGradient,
            valeur: filtreStatut,
            onChanged: onFiltreStatutChanged,
          ),
        ),
        Expanded(
          child: filtreActif
              ? _buildArticlesFiltres(context)
              : (familleSelectionnee == null
                  ? _buildFamilles(context)
                  : _buildArticles(context)),
        ),
      ],
    );
  }

  Widget _buildArticlesFiltres(BuildContext context) {
    final accent = tarif.accentGradient;
    final resultats = _articlesFiltres;

    if (resultats.isEmpty) {
      return Center(
        child: Text(
          recherche.trim().isNotEmpty
              ? 'Aucun article ne correspond à "${recherche.trim()}".'
              : 'Aucun article ${filtreStatut == StatutArticle.promo ? 'en promo' : 'en nouveauté'} pour le moment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final grille = _grilleArticles(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                _libelleResultats(resultats.length),
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grille.colonnes,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: grille.ratio,
                ),
                itemCount: resultats.length,
                itemBuilder: (context, index) {
                  final article = resultats[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: grille.largeurCarteMax),
                      child: ArticleCard(
                        article: article,
                        modePrix: modePrix,
                        accent: accent,
                        onTap: () => afficherFicheArticle(
                          context,
                          article: article,
                          modePrix: modePrix,
                          accent: accent,
                        ),
                        onEdit: isAdmin ? () => onEdit(article) : null,
                        onDelete: isAdmin ? () => onDelete(article) : null,
                        onAjouterPanier: () => onAjouterPanier(article),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFamilles(BuildContext context) {
    final accent = tarif.accentGradient;

    if (familles.isEmpty) {
      return Center(
        child: Text(
          isAdmin
              ? 'Aucune famille pour le moment.\nUtilisez le bouton "+" pour en créer une.'
              : 'Aucune famille pour le moment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 5
            : width > 900
                ? 4
                : width > 600
                    ? 3
                    : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Text(
                'Choisir une famille',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.05,
                ),
                itemCount: familles.length,
                itemBuilder: (context, index) {
                  final famille = familles[index];
                  return FamilleCard(
                    nom: famille,
                    nombreArticles: _nombreArticlesPourFamille(famille),
                    accent: accent,
                    onTap: () => onFamilleSelectionnee(famille),
                    onEdit: isAdmin ? () => onEditFamille(famille) : null,
                    onDelete: isAdmin ? () => onDeleteFamille(famille) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArticles(BuildContext context) {
    final accent = tarif.accentGradient;
    final articlesFiltres = _articlesDeLaFamille;
    return LayoutBuilder(
      builder: (context, constraints) {
        final grille = _grilleArticles(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 24, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => onFamilleSelectionnee(null),
                    icon: const Icon(Icons.arrow_back,
                        color: Color(0xFF1B3B5F), size: 20),
                  ),
                  Text(
                    familleSelectionnee!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3B5F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${articlesFiltres.length} article${articlesFiltres.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: articlesFiltres.isEmpty
                  ? Center(
                      child: Text(
                        isAdmin
                            ? 'Aucun article dans cette famille.\nUtilisez le bouton "+" pour en ajouter.'
                            : 'Aucun article dans cette famille.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.black.withValues(alpha: 0.45)),
                      ),
                    )
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grille.colonnes,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: grille.ratio,
                ),
                itemCount: articlesFiltres.length,
                itemBuilder: (context, index) {
                  final article = articlesFiltres[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: grille.largeurCarteMax),
                      child: ArticleCard(
                        article: article,
                        modePrix: modePrix,
                        accent: accent,
                        onTap: () => afficherFicheArticle(
                          context,
                          article: article,
                          modePrix: modePrix,
                          accent: accent,
                        ),
                        onEdit: isAdmin ? () => onEdit(article) : null,
                        onDelete: isAdmin ? () => onDelete(article) : null,
                        onAjouterPanier: () => onAjouterPanier(article),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarreRecherche extends StatefulWidget {
  final String valeur;
  final List<Color> accent;
  final ValueChanged<String> onChanged;

  const _BarreRecherche({
    required this.valeur,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<_BarreRecherche> createState() => _BarreRechercheState();
}

class _BarreRechercheState extends State<_BarreRecherche> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.valeur);

  @override
  void didUpdateWidget(covariant _BarreRecherche oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valeur != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.valeur,
        selection: TextSelection.collapsed(offset: widget.valeur.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un article (nom, code, code-barre)…',
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35)),
          prefixIcon: Icon(Icons.search, color: accent.last, size: 20),
          suffixIcon: widget.valeur.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.black38,
                  onPressed: () => widget.onChanged(''),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FiltreStatutBar extends StatelessWidget {
  final List<Color> accent;
  final StatutArticle? valeur;
  final ValueChanged<StatutArticle?> onChanged;

  const _FiltreStatutBar({
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
          _puce(context, null, 'Tous', Icons.grid_view_rounded, null),
          const SizedBox(width: 8),
          _puce(context, StatutArticle.promo, 'Promo',
              StatutArticle.promo.icone, StatutArticle.promo.degradeBandeau),
          const SizedBox(width: 8),
          _puce(
              context,
              StatutArticle.nouveaute,
              'Nouveauté',
              StatutArticle.nouveaute.icone,
              StatutArticle.nouveaute.degradeBandeau),
        ],
      ),
    );
  }

  Widget _puce(BuildContext context, StatutArticle? statut, String libelle,
      IconData icone, List<Color>? degrade) {
    final selectionne = valeur == statut;
    final couleur = degrade?.last ?? accent.last;
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
            gradient: selectionne
                ? LinearGradient(colors: degrade ?? accent)
                : null,
            border: Border.all(
              color: selectionne
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone,
                  size: 15, color: selectionne ? Colors.white : couleur),
              const SizedBox(width: 6),
              Text(
                libelle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color:
                      selectionne ? Colors.white : const Color(0xFF1B3B5F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
