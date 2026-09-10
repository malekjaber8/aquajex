import 'package:flutter/material.dart';

class FamilleCard extends StatefulWidget {
  final String nom;
  final int nombreArticles;
  final List<Color> accent;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FamilleCard({
    super.key,
    required this.nom,
    required this.nombreArticles,
    required this.accent,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FamilleCard> createState() => _FamilleCardState();
}

class _FamilleCardState extends State<FamilleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _hovering ? 1.02 : 1.0,
            _hovering ? 1.02 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovering
                ? accent.last.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.12 : 0.05),
              blurRadius: _hovering ? 18 : 8,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            splashColor: accent.last.withValues(alpha: 0.10),
            child: Stack(
              children: [
                if (widget.onEdit != null || widget.onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (widget.onEdit != null)
                          _MiniIconButton(
                            icon: Icons.edit_outlined,
                            onTap: widget.onEdit,
                          ),
                        if (widget.onEdit != null && widget.onDelete != null)
                          const SizedBox(width: 6),
                        if (widget.onDelete != null)
                          _MiniIconButton(
                            icon: Icons.delete_outline,
                            onTap: widget.onDelete,
                            danger: true,
                          ),
                      ],
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 26,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.nom,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: const Color(0xFF1B3B5F),
                            shadows: [
                              Shadow(
                                color: accent.last.withValues(alpha: 0.15),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.last.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.nombreArticles} article${widget.nombreArticles > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: accent.last,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  const _MiniIconButton({required this.icon, this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 16,
            color: danger ? Colors.redAccent : const Color(0xFF1B3B5F),
          ),
        ),
      ),
    );
  }
}
