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

  late final CatalogueRepository _repoAquajex =
      CatalogueRepository(Tarif.aquajex);
  late final CatalogueRepository _repoCinqFreres =
      CatalogueRepository(Tarif.cinqFreres);

  List<ArticleAvecTarif> _articlesPromo = [];
  List<ArticleAvecTarif> _articlesNouveaute = [];
  List<String> _famillesAquajex = [];
  List<String> _famillesCinqFreres = [];

  StreamSubscription<List<ArticleAvecTarif>>? _promoSub;
  StreamSubscription<List<ArticleAvecTarif>>? _nouveauteSub;
  StreamSubscription<List<String>>? _famillesAquajexSub;
  StreamSubscription<List<String>>? _famillesCinqFreresSub;

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
    _famillesAquajexSub = _repoAquajex.streamFamilles().listen((familles) {
      if (!mounted) return;
      setState(() => _famillesAquajex = familles);
    }, onError: (_) {});
    _famillesCinqFreresSub =
        _repoCinqFreres.streamFamilles().listen((familles) {
      if (!mounted) return;
      setState(() => _famillesCinqFreres = familles);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _promoSub?.cancel();
    _nouveauteSub?.cancel();
    _famillesAquajexSub?.cancel();
    _famillesCinqFreresSub?.cancel();
    super.dispose();
  }

  /// Le premier article en vedette (promo, sinon nouveauté) pour ce tarif —
  /// utilisé comme visuel sur la carte marque de l'écran d'accueil.
  ArticleAvecTarif? _vedettePour(Tarif tarif) {
    for (final a in _articlesPromo) {
      if (a.tarif == tarif) return a;
    }
    for (final a in _articlesNouveaute) {
      if (a.tarif == tarif) return a;
    }
    return null;
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

  void _ouvrirCatalogue(
    Tarif tarif, {
    StatutArticle? filtreStatut,
    String? familleInitiale,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogueScreen(
          tarif: tarif,
          modePrix: _modePrix,
          isAdmin: widget.isAdmin,
          filtreStatutInitial: filtreStatut,
          familleInitiale: familleInitiale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const largeurMax = 1400.0;

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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 30),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: largeurMax),
                      child: Column(
                        children: [
                          LayoutBuilder(
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
                              final nouveauteBanniere =
                                  _articlesNouveaute.isEmpty
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
                                            filtreStatut:
                                                StatutArticle.nouveaute,
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
                              final Widget contenu;
                              if (banniere.length == 1) {
                                contenu = banniere.first;
                              } else if (isWide) {
                                contenu = IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: banniere[0]),
                                      const SizedBox(width: 20),
                                      Expanded(child: banniere[1]),
                                    ],
                                  ),
                                );
                              } else {
                                contenu = Column(
                                  children: [
                                    banniere[0],
                                    const SizedBox(height: 16),
                                    banniere[1],
                                  ],
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 28),
                                child: contenu,
                              );
                            },
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 700;
                              final cartes = [
                                _LigneMarque(
                                  tarif: Tarif.aquajex,
                                  vedette: _vedettePour(Tarif.aquajex),
                                  familles: _famillesAquajex,
                                  onTap: () =>
                                      _ouvrirCatalogue(Tarif.aquajex),
                                  onTapFamille: (f) => _ouvrirCatalogue(
                                    Tarif.aquajex,
                                    familleInitiale: f,
                                  ),
                                ),
                                _LigneMarque(
                                  tarif: Tarif.cinqFreres,
                                  vedette: _vedettePour(Tarif.cinqFreres),
                                  familles: _famillesCinqFreres,
                                  onTap: () =>
                                      _ouvrirCatalogue(Tarif.cinqFreres),
                                  onTapFamille: (f) => _ouvrirCatalogue(
                                    Tarif.cinqFreres,
                                    familleInitiale: f,
                                  ),
                                ),
                              ];
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: cartes[0]),
                                    const SizedBox(width: 20),
                                    Expanded(child: cartes[1]),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  cartes[0],
                                  const SizedBox(height: 20),
                                  cartes[1],
                                ],
                              );
                            },
                          ),
                          if (_articlesPromo.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _RangeeArticles(
                              titre: 'Nos articles en promo',
                              icone: Icons.local_offer_outlined,
                              accent: StatutArticle.promo.degradeBandeau!,
                              articles: _articlesPromo,
                              onTapArticle: (a) => _ouvrirCatalogue(
                                a.tarif,
                                filtreStatut: StatutArticle.promo,
                              ),
                              onVoirTout: () => _ouvrirCatalogue(
                                _articlesPromo.first.tarif,
                                filtreStatut: StatutArticle.promo,
                              ),
                            ),
                          ],
                          if (_articlesNouveaute.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _RangeeArticles(
                              titre: 'Nouveautés',
                              icone: Icons.auto_awesome_outlined,
                              accent: StatutArticle.nouveaute.degradeBandeau!,
                              articles: _articlesNouveaute,
                              onTapArticle: (a) => _ouvrirCatalogue(
                                a.tarif,
                                filtreStatut: StatutArticle.nouveaute,
                              ),
                              onVoirTout: () => _ouvrirCatalogue(
                                _articlesNouveaute.first.tarif,
                                filtreStatut: StatutArticle.nouveaute,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const _PiedDePage(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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

/// Bandeau vitrine pour un statut (promo ou nouveauté) : fond dégradé sombre
/// teinté de la couleur du statut, avec la photo du premier article
/// correspondant qui se fond dans le fond côté droit.
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
      Color.lerp(const Color(0xFF0E141D), accent.first, 0.32)!,
      Color.lerp(const Color(0xFF0E141D), accent.last, 0.50)!,
    ];
    final image = article.article.imageBytes;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 190),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: fond,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeurImage = constraints.maxWidth * 0.42;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: largeurImage,
                        child: Image.memory(image, fit: BoxFit.cover),
                      ),
                    if (image != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: largeurImage,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [fond.last, fond.last.withValues(alpha: 0)],
                              stops: const [0.0, 0.62],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 24, 20, 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
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
                            const SizedBox(height: 14),
                            Text(
                              titre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              sousTitre,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 11),
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
                                      fontSize: 13,
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
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte marque (Aquajex / Les Cinq Frères) divisée en trois panneaux sur
/// grand écran : visuel produit, nom + bouton, catégories rapides — repliée
/// en colonne sur petit écran.
class _LigneMarque extends StatelessWidget {
  final Tarif tarif;
  final ArticleAvecTarif? vedette;
  final List<String> familles;
  final VoidCallback onTap;
  final ValueChanged<String> onTapFamille;

  const _LigneMarque({
    required this.tarif,
    required this.vedette,
    required this.familles,
    required this.onTap,
    required this.onTapFamille,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;
    final categories = familles.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.last.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accent.first.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final large = constraints.maxWidth > 560;
          final panneauImage = SizedBox(
            height: large ? null : 150,
            child: _PanneauImageMarque(tarif: tarif, vedette: vedette),
          );
          final panneauInfo =
              _PanneauInfoMarque(tarif: tarif, accent: accent, onTap: onTap);
          final panneauCategories = categories.isEmpty
              ? null
              : _PanneauCategories(
                  categories: categories,
                  accent: accent,
                  vertical: large,
                  onTap: onTapFamille,
                );

          if (large) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: panneauImage),
                  Expanded(flex: 4, child: panneauInfo),
                  if (panneauCategories != null)
                    Expanded(flex: 3, child: panneauCategories),
                ],
              ),
            );
          }
          return Column(
            children: [
              panneauImage,
              panneauInfo,
              ?panneauCategories,
            ],
          );
        },
      ),
    );
  }
}

class _PanneauImageMarque extends StatelessWidget {
  final Tarif tarif;
  final ArticleAvecTarif? vedette;

  const _PanneauImageMarque({required this.tarif, required this.vedette});

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;
    final image = vedette?.article.imageBytes;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, accent.first, 0.08)!,
            Color.lerp(Colors.white, accent.last, 0.14)!,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -34,
            bottom: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.last.withValues(alpha: 0.16),
                    accent.last.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(image,
                        fit: BoxFit.contain, height: 140),
                  )
                : Image.asset(tarif.logoAsset, fit: BoxFit.contain, height: 100),
          ),
        ],
      ),
    );
  }
}

class _PanneauInfoMarque extends StatelessWidget {
  final Tarif tarif;
  final List<Color> accent;
  final VoidCallback onTap;

  const _PanneauInfoMarque({
    required this.tarif,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tarif.nom,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B3B5F),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accent),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: accent.last.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Voir le catalogue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanneauCategories extends StatelessWidget {
  final List<String> categories;
  final List<Color> accent;
  final bool vertical;
  final ValueChanged<String> onTap;

  const _PanneauCategories({
    required this.categories,
    required this.accent,
    required this.vertical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final liens = [
      for (final c in categories)
        _LienCategorie(nom: c, accent: accent, onTap: () => onTap(c)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: vertical
              ? BorderSide.none
              : BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          left: vertical
              ? BorderSide(color: Colors.black.withValues(alpha: 0.05))
              : BorderSide.none,
        ),
      ),
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final lien in liens) ...[
                  lien,
                  if (lien != liens.last) const SizedBox(height: 16),
                ],
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final lien in liens)
                  SizedBox(width: 140, child: lien),
              ],
            ),
    );
  }
}

class _LienCategorie extends StatelessWidget {
  final String nom;
  final List<Color> accent;
  final VoidCallback onTap;

  const _LienCategorie({
    required this.nom,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(_iconePourFamille(nom), size: 16, color: accent.last),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                nom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B3B5F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rangée horizontale défilable d'articles d'un statut donné (promo ou
/// nouveauté), mélangeant les deux catalogues, avec flèches de défilement.
class _RangeeArticles extends StatefulWidget {
  final String titre;
  final IconData icone;
  final List<Color> accent;
  final List<ArticleAvecTarif> articles;
  final ValueChanged<ArticleAvecTarif> onTapArticle;
  final VoidCallback onVoirTout;

  const _RangeeArticles({
    required this.titre,
    required this.icone,
    required this.accent,
    required this.articles,
    required this.onTapArticle,
    required this.onVoirTout,
  });

  @override
  State<_RangeeArticles> createState() => _RangeeArticlesState();
}

class _RangeeArticlesState extends State<_RangeeArticles> {
  static const double _largeurCarte = 156;
  static const double _espacement = 14;

  final ScrollController _scrollCtrl = ScrollController();

  void _defiler(double sens) {
    if (!_scrollCtrl.hasClients) return;
    final cible = (_scrollCtrl.offset +
            sens * (_largeurCarte + _espacement) * 2)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(cible,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icone, size: 16, color: widget.accent.last),
            const SizedBox(width: 8),
            Text(
              widget.titre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B3B5F),
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onVoirTout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: widget.accent.last,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: widget.accent.last),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _BoutonDefilement(
                icon: Icons.chevron_left, onTap: () => _defiler(-1)),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 190,
                child: ListView.separated(
                  controller: _scrollCtrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.articles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: _espacement),
                  itemBuilder: (context, index) => _CarteRangee(
                    data: widget.articles[index],
                    accent: widget.accent,
                    largeur: _largeurCarte,
                    onTap: () => widget.onTapArticle(widget.articles[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _BoutonDefilement(
                icon: Icons.chevron_right, onTap: () => _defiler(1)),
          ],
        ),
      ],
    );
  }
}

class _BoutonDefilement extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BoutonDefilement({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: const Color(0xFF1B3B5F)),
        ),
      ),
    );
  }
}

class _CarteRangee extends StatelessWidget {
  final ArticleAvecTarif data;
  final List<Color> accent;
  final double largeur;
  final VoidCallback onTap;

  const _CarteRangee({
    required this.data,
    required this.accent,
    required this.largeur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final article = data.article;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: largeur,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                              size: 28,
                              color: accent.last.withValues(alpha: 0.3),
                            ),
                          ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: accent),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          article.statut == StatutArticle.promo
                              ? 'PROMO'
                              : 'Nouveau',
                          style: const TextStyle(
                            fontSize: 9.5,
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
                child: Text(
                  article.designation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B5F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PiedDePage extends StatelessWidget {
  const _PiedDePage();

  static const _items = [
    (Icons.local_shipping_outlined, 'Livraison rapide', 'Partout en Tunisie'),
    (Icons.verified_outlined, 'Produits de qualité', 'Des marques de confiance'),
    (Icons.headset_mic_outlined, 'Service client', 'Toujours à votre écoute'),
    (Icons.favorite_border, 'Votre satisfaction', 'Notre priorité'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final tuiles = [
          for (final it in _items)
            _TuilePiedDePage(icone: it.$1, titre: it.$2, sousTitre: it.$3),
        ];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B3B5F), Color(0xFF11273E)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: wide
              ? Row(children: [for (final t in tuiles) Expanded(child: t)])
              : Wrap(
                  spacing: 20,
                  runSpacing: 18,
                  children: [
                    for (final t in tuiles)
                      SizedBox(
                        width: (constraints.maxWidth - 20) / 2,
                        child: t,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _TuilePiedDePage extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;

  const _TuilePiedDePage({
    required this.icone,
    required this.titre,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              Text(
                sousTitre,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icône approximative pour une famille de catalogue, choisie par
/// correspondance de mots-clés dans son nom (aucune icône n'est configurée
/// par famille dans l'admin, donc c'est une simple heuristique visuelle).
IconData _iconePourFamille(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('pomp')) return Icons.water_drop_outlined;
  if (n.contains('tuyau') || n.contains('raccord')) return Icons.plumbing_outlined;
  if (n.contains('robinet')) return Icons.water_outlined;
  if (n.contains('sanit')) return Icons.bathtub_outlined;
  if (n.contains('carrel')) return Icons.grid_view_outlined;
  if (n.contains('plomb')) return Icons.plumbing_outlined;
  if (n.contains('bat') || n.contains('bât')) return Icons.home_work_outlined;
  if (n.contains('access')) return Icons.build_outlined;
  if (n.contains('decor') || n.contains('déco')) return Icons.chair_outlined;
  if (n.contains('meuble')) return Icons.weekend_outlined;
  if (n.contains('tapis')) return Icons.texture_outlined;
  return Icons.category_outlined;
}
