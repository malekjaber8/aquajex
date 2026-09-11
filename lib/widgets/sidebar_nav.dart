import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String label;

  const SidebarItem({required this.icon, required this.label});
}

class SidebarNav extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Color> accent;
  final bool Function(int index)? enabled;

  const SidebarNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.accent,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        right: false,
        // Défile plutôt que déborder quand la fenêtre est trop courte pour
        // afficher tous les éléments (ex. après l'ajout d'une rubrique) —
        // sans ça, les derniers éléments pouvaient être coupés/inaccessibles.
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: _SidebarButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    enabled: enabled?.call(i) ?? true,
                    accent: accent,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final bool enabled;
  final List<Color> accent;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = selected
        ? Colors.white
        : enabled
        ? const Color(0xFF6B7A8D)
        : const Color(0xFF6B7A8D).withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected ? LinearGradient(colors: accent) : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(item.icon, size: 26, color: couleur),
              const SizedBox(height: 7),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: couleur,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de navigation basse (mobile), équivalent de [SidebarNav] pour les
/// petits écrans.
///
/// Si [primaryIndices] est fourni, seuls ces éléments sont affichés
/// directement ; les autres sont regroupés derrière un bouton "Plus" qui
/// ouvre une feuille de sélection — évite une barre trop encombrée quand
/// il y a beaucoup de rubriques.
class BottomNav extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Color> accent;
  final bool Function(int index)? enabled;
  final List<int>? primaryIndices;

  const BottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.accent,
    this.enabled,
    this.primaryIndices,
  });

  @override
  Widget build(BuildContext context) {
    final indicesPrincipaux =
        primaryIndices ?? [for (int i = 0; i < items.length; i++) i];
    final indicesRestants = [
      for (int i = 0; i < items.length; i++)
        if (!indicesPrincipaux.contains(i)) i,
    ];
    final plusActif = indicesRestants.contains(selectedIndex);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final i in indicesPrincipaux)
                Expanded(
                  child: _BottomNavButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    actif: enabled?.call(i) ?? true,
                    accent: accent,
                    onTap: () => onSelect(i),
                  ),
                ),
              if (indicesRestants.isNotEmpty)
                Expanded(
                  child: _BottomNavButton(
                    item: const SidebarItem(
                      icon: Icons.more_horiz_rounded,
                      label: 'Plus',
                    ),
                    selected: plusActif,
                    actif: true,
                    accent: accent,
                    onTap: () => _ouvrirPlus(context, indicesRestants),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirPlus(BuildContext context, List<int> indicesRestants) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final i in indicesRestants)
                Builder(
                  builder: (context) {
                    final actif = enabled?.call(i) ?? true;
                    final couleur = i == selectedIndex
                        ? accent.last
                        : actif
                        ? const Color(0xFF1B3B5F)
                        : const Color(0xFF1B3B5F).withValues(alpha: 0.35);
                    return ListTile(
                      enabled: actif,
                      leading: Icon(items[i].icon, color: couleur),
                      title: Text(
                        items[i].label,
                        style: TextStyle(
                          fontWeight: i == selectedIndex
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: couleur,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(i);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final bool actif;
  final List<Color> accent;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.actif,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = selected
        ? accent.last
        : actif
        ? const Color(0xFF6B7A8D)
        : const Color(0xFF6B7A8D).withValues(alpha: 0.35);
    return InkWell(
      onTap: actif ? onTap : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: couleur),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}
