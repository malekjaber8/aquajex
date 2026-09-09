import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
    // Rubans mélangeant les deux catalogues (Aquajex + Les Cinq Frères) :
    // seul l'écran d'accueil montre les deux marques ensemble.
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

  void _ouvrirCatalogue(Tarif tarif) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogueScreen(
          tarif: tarif,
          modePrix: _modePrix,
          isAdmin: widget.isAdmin,
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
                    const SizedBox(height: 40),
                    if (_articlesPromo.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 952),
                        child: _RubanArticles(
                          titre: 'EN CE MOMENT EN PROMO',
                          icone: Icons.local_offer_outlined,
                          accent: StatutArticle.promo.degradeBandeau!,
                          articles: _articlesPromo,
                          modePrix: _modePrix,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
                    if (_articlesNouveaute.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 952),
                        child: _RubanArticles(
                          titre: 'LES DERNIÈRES NOUVEAUTÉS',
                          icone: Icons.auto_awesome_outlined,
                          accent: StatutArticle.nouveaute.degradeBandeau!,
                          articles: _articlesNouveaute,
                          modePrix: _modePrix,
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

/// Bandeau animé qui fait défiler en continu les articles d'un statut donné
/// (promo ou nouveauté), en mélangeant les deux catalogues Aquajex / Les
/// Cinq Frères — utilisé uniquement sur l'écran d'accueil.
class _RubanArticles extends StatefulWidget {
  final String titre;
  final IconData icone;
  final List<Color> accent;
  final List<ArticleAvecTarif> articles;
  final ModePrix modePrix;

  const _RubanArticles({
    required this.titre,
    required this.icone,
    required this.accent,
    required this.articles,
    required this.modePrix,
  });

  @override
  State<_RubanArticles> createState() => _RubanArticlesState();
}

class _RubanArticlesState extends State<_RubanArticles>
    with SingleTickerProviderStateMixin {
  static const double _largeurCarte = 172;
  static const double _espacement = 12;
  static const double _vitessePixelsParSeconde = 26;

  final ScrollController _scrollCtrl = ScrollController();
  late final Ticker _ticker;
  Duration _dernierInstant = Duration.zero;

  double get _largeurUnite =>
      widget.articles.length * (_largeurCarte + _espacement);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_surTick)..start();
  }

  void _surTick(Duration elapsed) {
    if (widget.articles.isEmpty || !_scrollCtrl.hasClients) {
      _dernierInstant = elapsed;
      return;
    }
    final dt = (elapsed - _dernierInstant).inMicroseconds / 1e6;
    _dernierInstant = elapsed;
    final largeurUnite = _largeurUnite;
    if (largeurUnite <= 0 || dt <= 0 || dt > 0.25) return;
    double offset =
        _scrollCtrl.offset + _vitessePixelsParSeconde * dt;
    if (offset >= largeurUnite) offset -= largeurUnite;
    _scrollCtrl.jumpTo(offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SizedBox.shrink();
    // Liste dupliquée pour un défilement en boucle sans coupure visible.
    final items = [...widget.articles, ...widget.articles];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.accent),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.accent.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(widget.icone, color: Colors.white, size: 17),
                const SizedBox(width: 8),
                Text(
                  widget.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: _espacement),
              itemBuilder: (context, index) => _CarteRuban(
                data: items[index],
                modePrix: widget.modePrix,
                largeur: _largeurCarte,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteRuban extends StatelessWidget {
  final ArticleAvecTarif data;
  final ModePrix modePrix;
  final double largeur;

  const _CarteRuban({
    required this.data,
    required this.modePrix,
    required this.largeur,
  });

  @override
  Widget build(BuildContext context) {
    final article = data.article;
    final prix =
        modePrix == ModePrix.detail ? article.prixDetail : article.prixGros;

    return Container(
      width: largeur,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 62,
              height: 62,
              child: article.imageBytes != null
                  ? Image.memory(article.imageBytes!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFF3F5F8),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 22,
                        color: data.tarif.accentColor.withValues(alpha: 0.35),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: data.tarif.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.tarif.nom,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: data.tarif.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.designation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B5F),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${prix.toStringAsFixed(3)} DT',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: data.tarif.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
