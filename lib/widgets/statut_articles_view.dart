import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/mode_prix.dart';
import '../services/catalogue_repository.dart';

/// Rubrique Promotion/Nouveauté (mélange des deux catalogues), affichée à
/// l'identique depuis la page d'accueil et depuis chaque catalogue ouvert.
class StatutArticlesView extends StatelessWidget {
  final StatutArticle statut;
  final List<ArticleAvecTarif> articles;
  final ModePrix modePrix;
  final ValueChanged<ArticleAvecTarif> onTapArticle;

  const StatutArticlesView({
    super.key,
    required this.statut,
    required this.articles,
    required this.modePrix,
    required this.onTapArticle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = statut.degradeBandeau!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 4),
          child: Row(
            children: [
              Icon(statut.icone, color: accent.last, size: 22),
              const SizedBox(width: 10),
              Text(
                statut.libelle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B3B5F),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: articles.isEmpty
              ? Center(
                  child: Text(
                    'Aucun article en ${statut.libelle.toLowerCase()} pour le moment',
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
                  itemCount: articles.length,
                  itemBuilder: (context, i) => CarteArticleMixte(
                    data: articles[i],
                    modePrix: modePrix,
                    onTap: () => onTapArticle(articles[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Mini-fiche article utilisée dans les listes Promotion/Nouveauté, qui
/// mélangent les deux catalogues (Aquajex / Les Cinq Frères).
class CarteArticleMixte extends StatelessWidget {
  final ArticleAvecTarif data;
  final ModePrix modePrix;
  final VoidCallback onTap;

  const CarteArticleMixte({
    super.key,
    required this.data,
    required this.modePrix,
    required this.onTap,
  });

  String _formaterPrix(double prix) {
    final parts = prix.toStringAsFixed(3).split('.');
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
    final article = data.article;
    final accent = data.tarif.accentGradient;
    final prix = modePrix == ModePrix.detail
        ? article.prixDetail
        : article.prixGros;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  article.imageBytes != null
                      ? Image.memory(article.imageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFF3F5F8),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 30,
                            color: accent.last.withValues(alpha: 0.3),
                          ),
                        ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: accent),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.tarif.nom,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.designation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3B5F),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formaterPrix(prix)} DT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accent.last,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
