import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/mode_prix.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final ModePrix modePrix;
  final List<Color> accent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAjouterPanier;

  const ArticleCard({
    super.key,
    required this.article,
    required this.modePrix,
    required this.accent,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAjouterPanier,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _hovering = false;

  double get _prix => widget.article.prixPour(widget.modePrix);
  double? get _prixBarre => widget.article.prixBarrePour(widget.modePrix);
  int? get _pourcentage =>
      widget.article.pourcentageRemisePour(widget.modePrix);

  String get _prixFormate => _formatMontant(_prix);

  String _formatMontant(double montant) {
    final entier = montant.toStringAsFixed(3);
    final parts = entier.split('.');
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
    final accent = widget.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _hovering ? 1.015 : 1.0,
            _hovering ? 1.015 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovering
                ? accent.last.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.12 : 0.06),
              blurRadius: _hovering ? 20 : 10,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        color: const Color(0xFFF3F5F8),
                        child: widget.article.imageBytes != null
                            ? Image.memory(
                                widget.article.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 46,
                                  color: accent.last.withValues(alpha: 0.35),
                                ),
                              ),
                      ),
                    ),
                    if (widget.article.statut != StatutArticle.normal)
                      Positioned(
                        top: 14,
                        left: -36,
                        child: Transform.rotate(
                          angle: -0.7853981633974483,
                          child: Container(
                            width: 140,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.article.statut.degradeBandeau!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.article.statut == StatutArticle.promo
                                  ? 'PROMO'
                                  : 'NOUVEAU',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!widget.article.disponible)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Indisponible',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                            if (widget.onEdit != null &&
                                widget.onDelete != null)
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
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.article.codeArticle != null ||
                          widget.article.codeBarre != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              if (widget.article.codeArticle != null)
                                Flexible(
                                  child: Text(
                                    widget.article.codeArticle!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: accent.last,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              if (widget.article.codeBarre != null) ...[
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    widget.article.codeBarre!,
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (widget.article.colisage != null)
                        Text(
                          'Colisage : ${widget.article.colisage}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        widget.article.designation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B3B5F),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_prixBarre != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Text(
                                '${_formatMontant(_prixBarre!)} DT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withValues(alpha: 0.4),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              if (_pourcentage != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '-$_pourcentage%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _prixFormate,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: accent.last,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    'DT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accent.last.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onAjouterPanier != null)
                            Material(
                              color: widget.article.disponible
                                  ? accent.last
                                  : Colors.grey.shade400,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: widget.article.disponible
                                    ? widget.onAjouterPanier
                                    : null,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.add_shopping_cart,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
