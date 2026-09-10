import 'dart:async';

import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';
import '../services/catalogue_repository.dart';
import '../widgets/decorative_background.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/statut_articles_view.dart';
import 'catalogue_screen.dart';

const _navItems = [
  SidebarItem(icon: Icons.grid_view_rounded, label: 'Catalogue'),
  SidebarItem(icon: Icons.local_offer_outlined, label: 'Promotion'),
  SidebarItem(icon: Icons.auto_awesome_outlined, label: 'Nouveauté'),
  SidebarItem(icon: Icons.people_outline, label: 'Clients'),
  SidebarItem(icon: Icons.request_quote_outlined, label: 'Commandes'),
  SidebarItem(icon: Icons.sticky_note_2_outlined, label: 'Notes'),
];

const _indexCatalogue = 0;
const _indexPromotion = 1;
const _indexNouveaute = 2;

class TarifSelectionScreen extends StatefulWidget {
  final bool isAdmin;

  const TarifSelectionScreen({super.key, required this.isAdmin});

  @override
  State<TarifSelectionScreen> createState() => _TarifSelectionScreenState();
}

class _TarifSelectionScreenState extends State<TarifSelectionScreen> {
  ModePrix _modePrix = ModePrix.detail;
  int _selectedIndex = _indexCatalogue;

  List<ArticleAvecTarif> _articlesPromo = [];
  List<ArticleAvecTarif> _articlesNouveaute = [];
  StreamSubscription<List<ArticleAvecTarif>>? _promoSub;
  StreamSubscription<List<ArticleAvecTarif>>? _nouveauteSub;

  @override
  void initState() {
    super.initState();
    // Mélange les deux catalogues (Aquajex + Les Cinq Frères) pour les
    // rubriques Promotion/Nouveauté du menu latéral.
    _promoSub = CatalogueRepository.streamArticlesParStatut(StatutArticle.promo)
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

  static const _accentNeutre = [Color(0xFF1B3B5F), Color(0xFFC9A24B)];

  Widget _buildContenuCatalogue() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A24B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFC9A24B).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'AQUAJEX  •  LES CINQ FRÈRES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: const Color(0xFF1B3B5F).withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 22),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1.15,
              ),
              children: [
                TextSpan(
                  text: 'CHOISIR UN\n',
                  style: TextStyle(color: Color(0xFF1B3B5F)),
                ),
                TextSpan(
                  text: 'CATALOGUE',
                  style: TextStyle(color: Color(0xFF2C8FA0)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
            'SÉLECTIONNEZ LA SOCIÉTÉ POUR AFFICHER LES TARIFS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.4),
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 48),
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
                children: [cards[0], const SizedBox(height: 24), cards[1]],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContenuStatut(
    StatutArticle statut,
    List<ArticleAvecTarif> articles,
  ) {
    return StatutArticlesView(
      statut: statut,
      articles: articles,
      modePrix: _modePrix,
      onTapArticle: (data) => _ouvrirCatalogue(data.tarif),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        final Widget corpsPrincipal;
        switch (_selectedIndex) {
          case _indexPromotion:
            corpsPrincipal = _buildContenuStatut(
              StatutArticle.promo,
              _articlesPromo,
            );
            break;
          case _indexNouveaute:
            corpsPrincipal = _buildContenuStatut(
              StatutArticle.nouveaute,
              _articlesNouveaute,
            );
            break;
          default:
            corpsPrincipal = _buildContenuCatalogue();
        }

        final contenu = Stack(
          children: [
            SafeArea(child: corpsPrincipal),
            Positioned(
              top: 16,
              right: 16,
              child: _ModePrixBadge(
                modePrix: _modePrix,
                onTap: _choisirModePrix,
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecorativeBackground(
            child: mobile
                ? contenu
                : Row(
                    children: [
                      SidebarNav(
                        items: _navItems,
                        selectedIndex: _selectedIndex,
                        onSelect: (i) => setState(() => _selectedIndex = i),
                        accent: _accentNeutre,
                        enabled: (i) =>
                            i == _indexCatalogue ||
                            i == _indexPromotion ||
                            i == _indexNouveaute,
                      ),
                      Expanded(child: contenu),
                    ],
                  ),
          ),
          bottomNavigationBar: mobile
              ? BottomNav(
                  items: _navItems,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  accent: _accentNeutre,
                  enabled: (i) =>
                      i == _indexCatalogue ||
                      i == _indexPromotion ||
                      i == _indexNouveaute,
                )
              : null,
        );
      },
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
              Icon(
                Icons.sell_outlined,
                size: 15,
                color: Colors.black.withValues(alpha: 0.35),
              ),
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
                color: selectionne ? const Color(0xFF1B3B5F) : Colors.black38,
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
            _hovering ? 1.02 : 1.0,
            _hovering ? 1.02 : 1.0,
            1.0,
            1.0,
          ),
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
                          vertical: 36,
                          horizontal: 32,
                        ),
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
                                horizontal: 22,
                                vertical: 12,
                              ),
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
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Colors.white,
                                  ),
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
