import 'package:flutter/material.dart';

/// Barre de recherche réutilisée par les différentes sections (catalogue,
/// clients, commandes) — même style partout dans l'app.
class BarreRecherche extends StatefulWidget {
  final String valeur;
  final List<Color> accent;
  final String hintText;
  final ValueChanged<String> onChanged;

  const BarreRecherche({
    super.key,
    required this.valeur,
    required this.accent,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<BarreRecherche> createState() => _BarreRechercheState();
}

class _BarreRechercheState extends State<BarreRecherche> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valeur,
  );

  @override
  void didUpdateWidget(covariant BarreRecherche oldWidget) {
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
          hintText: widget.hintText,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
