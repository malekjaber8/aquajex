import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/mode_prix.dart';

Future<void> afficherFicheArticle(
  BuildContext context, {
  required Article article,
  required ModePrix modePrix,
  required List<Color> accent,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: _ArticleDetailCard(
        article: article,
        modePrix: modePrix,
        accent: accent,
      ),
    ),
  );
}

class _ArticleDetailCard extends StatelessWidget {
  final Article article;
  final ModePrix modePrix;
  final List<Color> accent;

  const _ArticleDetailCard({
    required this.article,
    required this.modePrix,
    required this.accent,
  });

  double get _prix =>
      modePrix == ModePrix.detail ? article.prixDetail : article.prixGros;

  String get _prixFormate {
    final parts = _prix.toStringAsFixed(3).split('.');
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
    final infos = <(String, String)>[
      if (article.codeArticle != null) ('Code article', article.codeArticle!),
      if (article.codeBarre != null) ('Code à barre', article.codeBarre!),
      if (article.taille != null) ('Taille', article.taille!),
      if (article.colisage != null) ('Colisage', '${article.colisage}'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Container(
                      color: const Color(0xFFF3F5F8),
                      child: article.imageBytes != null
                          ? Image.memory(article.imageBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: accent.last.withValues(alpha: 0.35),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.last.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categorie,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent.last,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.designation,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3B5F),
                        height: 1.25,
                      ),
                    ),
                    if (infos.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < infos.length; i++) ...[
                              if (i > 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    infos[i].$1,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    infos[i].$2,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B3B5F),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          modePrix.libelle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _prixFormate,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: accent.last,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'DT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accent.last.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
