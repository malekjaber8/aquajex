import 'dart:async';

import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';
import '../services/catalogue_repository.dart';
import '../widgets/decorative_background.dart';
import 'catalogue_screen.dart';

class TarifSelectionScreen extends StatefulWidget {
  final bool isAdmin;

  const TarifSelectionScreen({super.key, required this.isAdmin});

  @override
  State<TarifSelectionScreen> createState() => _TarifSelectionScreenState();
}

class _TarifSelectionScreenState extends State<TarifSelectionScreen> {
  ModePrix _modePrix = ModePrix.detail;

  List<ArticleAvecTarif> _articlesPromo = [];
  List<ArticleAvecTarif> _articlesNouveaute = [];
  StreamSubscription<List<ArticleAvecTarif>>? _promoSub;
  StreamSubscription<List<ArticleAvecTarif>>? _nouveauteSub;

  @override
  void initState() {
    super.initState();
    // Mélange les deux catalogues (Aquajex + Les Cinq Frères) : seul l'écran
    // d'accueil montre les deux marques ensemble.
    _promoSub =
        CatalogueRepository.streamArticlesParStatut(StatutArticle.promo)
            .listen((articles) {
      if (!mounted) return;
      setState(() => _articlesPromo = articles);
    }, onError: (_) {});
    _nouveauteSub =
        CatalogueRepository.streamArticlesParStatut(StatutArticle.nouveaute)
            .listen((articles) {
      if (!mounted) return;
      setState(() => _articlesNouveaute = articles);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _promoSub?.cancel();
    _nouveauteSub?.cancel();
    super.dispose();
  }

  Future<void> _choisirModePrix() async {
    final choix = await showModalBottomSheet<ModePrix>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModePrixSheet(modeActuel: _modePrix),
    );
    if (choix != null) {
      setState(() => _modePrix = choix);
    }
  }

  void _ouvrirCatalogue(Tarif tarif, {StatutArticle? filtreStatut}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogueScreen(
          tarif: tarif,
          modePrix: _modePrix,
          isAdmin: widget.isAdmin,
          filtreStatutInitial: filtreStatut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(
                            text: 'Choisir un ',
                            style: TextStyle(color: Color(0xFF1B3B5F)),
                          ),
                          TextSpan(
                            text: 'catalogue',
                            style: TextStyle(color: Color(0xFF2C8FA0)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B3B5F), Color(0xFFC9A24B)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Sélectionnez la société pour afficher les tarifs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: Colors.black.withValues(alpha: 0.5),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 36),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 952),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final promoBanniere = _articlesPromo.isEmpty
                              ? null
                              : _BanniereStatut(
                                  statut: StatutArticle.promo,
                                  titre: 'NOS ARTICLES EN PROMO',
                                  sousTitre:
                                      'Qualité • Prix avantageux • Stocks limités',
                                  bouton: 'Découvrir',
                                  article: _articlesPromo.first,
                                  onTap: () => _ouvrirCatalogue(
                                    _articlesPromo.first.tarif,
                                    filtreStatut: StatutArticle.promo,
                                  ),
                                );
                          final nouveauteBanniere = _articlesNouveaute.isEmpty
                              ? null
                              : _BanniereStatut(
                                  statut: StatutArticle.nouveaute,
                                  titre: 'NOUVEAUTÉS',
                                  sousTitre:
                                      'Découvrez nos derniers arrivages',
                                  bouton: 'Voir les nouveautés',
                                  article: _articlesNouveaute.first,
                                  onTap: () => _ouvrirCatalogue(
                                    _articlesNouveaute.first.tarif,
                                    filtreStatut: StatutArticle.nouveaute,
                                  ),
                                );
                          if (promoBanniere == null &&
                              nouveauteBanniere == null) {
                            return const SizedBox.shrink();
                          }
                          final isWide = constraints.maxWidth > 700;
                          final banniere = [
                            ?promoBanniere,
                            ?nouveauteBanniere,
                          ];
                          if (banniere.length == 1) return banniere.first;
                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: banniere[0]),
                                const SizedBox(width: 20),
                                Expanded(child: banniere[1]),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              banniere[0],
                              const SizedBox(height: 16),
                              banniere[1],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 36),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final cards = [
                          _TarifCard(
                            tarif: Tarif.aquajex,
                            onTap: () => _ouvrirCatalogue(Tarif.aquajex),
                          ),
                          _TarifCard(
                            tarif: Tarif.cinqFreres,
                            onTap: () => _ouvrirCatalogue(Tarif.cinqFreres),
                          ),
                        ];
                        if (isWide) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 32),
                              Expanded(child: cards[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 24),
                            cards[1],
                          ],
                        );
                      },
                    ),
                    if (_articlesPromo.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 952),
                        child: _RangeeArticles(
                          titre: 'Nos articles en promo',
                          icone: Icons.local_offer_outlined,
                          accent: StatutArticle.promo.degradeBandeau!,
                          articles: _articlesPromo,
                          modePrix: _modePrix,
                          onTapArticle: (a) => _ouvrirCatalogue(
                            a.tarif,
                            filtreStatut: StatutArticle.promo,
                          ),
                        ),
                      ),
                    ],
                    if (_articlesNouveaute.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 952),
                        child: _RangeeArticles(
                          titre: 'Nouveautés',
                          icone: Icons.auto_awesome_outlined,
                          accent: StatutArticle.nouveaute.degradeBandeau!,
                          articles: _articlesNouveaute,
                          modePrix: _modePrix,
                          onTapArticle: (a) => _ouvrirCatalogue(
                            a.tarif,
                            filtreStatut: StatutArticle.nouveaute,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _ModePrixBadge(
                modePrix: _modePrix,
                onTap: _choisirModePrix,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePrixBadge extends StatelessWidget {
  final ModePrix modePrix;
  final VoidCallback onTap;

  const _ModePrixBadge({required this.modePrix, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined,
                  size: 15, color: Colors.black.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                'Tarif : ${modePrix.libelleCourt}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.45),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePrixSheet extends StatelessWidget {
  final ModePrix modeActuel;

  const _ModePrixSheet({required this.modeActuel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choisir le tarif à afficher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3B5F),
                ),
              ),
              const SizedBox(height: 20),
              for (final mode in ModePrix.values) ...[
                _ModePrixOption(
                  mode: mode,
                  selectionne: mode == modeActuel,
                  onTap: () => Navigator.of(context).pop(mode),
                ),
                if (mode != ModePrix.values.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePrixOption extends StatelessWidget {
  final ModePrix mode;
  final bool selectionne;
  final VoidCallback onTap;

  const _ModePrixOption({
    required this.mode,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionne
          ? const Color(0xFF1B3B5F).withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                selectionne
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selectionne
                    ? const Color(0xFF1B3B5F)
                    : Colors.black38,
              ),
              const SizedBox(width: 14),
              Text(
                mode.libelle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selectionne ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF1B3B5F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarifCard extends StatefulWidget {
  final Tarif tarif;
  final VoidCallback onTap;

  const _TarifCard({required this.tarif, required this.onTap});

  @override
  State<_TarifCard> createState() => _TarifCardState();
}

class _TarifCardState extends State<_TarifCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.tarif.accentGradient;
    const radius = 24.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
              _hovering ? 1.02 : 1.0, _hovering ? 1.02 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 380, maxWidth: 460),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color.lerp(Colors.white, accent.last, 0.06)!,
            ],
          ),
          border: Border.all(
            color: accent.last.withValues(alpha: _hovering ? 0.55 : 0.22),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.first.withValues(alpha: _hovering ? 0.28 : 0.16),
              blurRadius: _hovering ? 28 : 18,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: accent.last.withValues(alpha: 0.12),
              highlightColor: accent.last.withValues(alpha: 0.06),
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    bottom: -60,
                    child: Transform.rotate(
                      angle: 0.6,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.first.withValues(alpha: 0.06),
                              accent.last.withValues(alpha: 0.14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    top: -50,
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              accent.first.withValues(alpha: 0.08),
                              accent.first.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: accent),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 36, horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Container(
                            width: 240,
                            height: 220,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.last.withValues(alpha: 0.10),
                                  accent.last.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Image.asset(
                              widget.tarif.logoAsset,
                              fit: BoxFit.contain,
                              width: 200,
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.tarif.nom,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3B5F),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: accent),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.last.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Voir le catalogue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau vitrine pour un statut (promo ou nouveauté), avec un fond sombre
/// teinté de la couleur du statut et le premier article correspondant en
/// vedette — inspiré des bannières promotionnelles classiques d'e-commerce.
class _BanniereStatut extends StatelessWidget {
  final StatutArticle statut;
  final String titre;
  final String sousTitre;
  final String bouton;
  final ArticleAvecTarif article;
  final VoidCallback onTap;

  const _BanniereStatut({
    required this.statut,
    required this.titre,
    required this.sousTitre,
    required this.bouton,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = statut.degradeBandeau!;
    final fond = [
      Color.lerp(const Color(0xFF0E141D), accent.first, 0.30)!,
      Color.lerp(const Color(0xFF0E141D), accent.last, 0.46)!,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 172),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fond,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -34,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statut.icone,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(
                                    statut == StatutArticle.promo
                                        ? 'EN CE MOMENT'
                                        : 'FRAÎCHEMENT ARRIVÉ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              titre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sousTitre,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bouton,
                                    style: TextStyle(
                                      color: accent.last,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward,
                                      size: 14, color: accent.last),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 104,
                        height: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: article.article.imageBytes != null
                                ? Image.memory(article.article.imageBytes!,
                                    fit: BoxFit.cover)
                                : Container(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    child: Icon(
                                      statut.icone,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rangée horizontale défilable d'articles d'un statut donné (promo ou
/// nouveauté), mélangeant les deux catalogues.
class _RangeeArticles extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<Color> accent;
  final List<ArticleAvecTarif> articles;
  final ModePrix modePrix;
  final ValueChanged<ArticleAvecTarif> onTapArticle;

  const _RangeeArticles({
    required this.titre,
    required this.icone,
    required this.accent,
    required this.articles,
    required this.modePrix,
    required this.onTapArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: accent.last),
            const SizedBox(width: 8),
            Text(
              titre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B3B5F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _CarteRangee(
              data: articles[index],
              accent: accent,
              modePrix: modePrix,
              onTap: () => onTapArticle(articles[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarteRangee extends StatelessWidget {
  final ArticleAvecTarif data;
  final List<Color> accent;
  final ModePrix modePrix;
  final VoidCallback onTap;

  const _CarteRangee({
    required this.data,
    required this.accent,
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
    final prix =
        modePrix == ModePrix.detail ? article.prixDetail : article.prixGros;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          clipBehavior: Clip.antiAlias,
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
                              size: 24,
                              color: accent.last.withValues(alpha: 0.3),
                            ),
                          ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: accent),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.tarif.nom,
                          style: const TextStyle(
                            fontSize: 7.5,
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
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formaterPrix(prix)} DT',
                      style: TextStyle(
                        fontSize: 11.5,
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
      ),
    );
  }
}
