import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/tarif.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/section_placeholder.dart';

class NotesSection extends StatelessWidget {
  final Tarif tarif;
  final List<Note> notes;
  final ValueChanged<Note> onEdit;
  final ValueChanged<Note> onDelete;
  final VoidCallback onAjouter;

  const NotesSection({
    super.key,
    required this.tarif,
    required this.notes,
    required this.onEdit,
    required this.onDelete,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;

    if (notes.isEmpty) {
      return SectionPlaceholder(
        icon: Icons.sticky_note_2_outlined,
        titre: 'Aucune note pour le moment',
        sousTitre: 'Notez les remarques d\'un client ou\nun rappel pour votre prochaine visite.',
        accent: accent,
        actionLabel: 'Ajouter une note',
        onAction: onAjouter,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteTile(
          note: note,
          accent: accent,
          onTap: () => onEdit(note),
          onEdit: () => onEdit(note),
          onDelete: () => onDelete(note),
        );
      },
    );
  }
}
