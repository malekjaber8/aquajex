import 'package:flutter/material.dart';

import '../models/client.dart';

class ClientTile extends StatefulWidget {
  final Client client;
  final List<Color> accent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClientTile({
    super.key,
    required this.client,
    required this.accent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<ClientTile> {
  bool _hovering = false;

  String get _initiales {
    final p = widget.client.prenom.isNotEmpty ? widget.client.prenom[0] : '';
    final n = widget.client.nom.isNotEmpty ? widget.client.nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final c = widget.client;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering
                ? accent.last.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.08 : 0.04),
              blurRadius: _hovering ? 14 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: accent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nomComplet,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B3B5F),
                          ),
                        ),
                        if (c.nomSociete != null || c.telephone != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [
                                c.nomSociete,
                                c.telephone,
                              ].where((e) => e != null).join(' · '),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        color: const Color(0xFF1B3B5F),
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 19),
                        color: Colors.redAccent,
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
