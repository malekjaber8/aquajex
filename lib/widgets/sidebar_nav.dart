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
class BottomNav extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Color> accent;
  final bool Function(int index)? enabled;

  const BottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.accent,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
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
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final actif = enabled?.call(i) ?? true;
                      final couleur = i == selectedIndex
                          ? accent.last
                          : actif
                          ? const Color(0xFF6B7A8D)
                          : const Color(0xFF6B7A8D).withValues(alpha: 0.35);
                      return InkWell(
                        onTap: actif ? () => onSelect(i) : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(items[i].icon, size: 22, color: couleur),
                            const SizedBox(height: 3),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: i == selectedIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: couleur,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
