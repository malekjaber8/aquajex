import 'package:flutter/material.dart';
import '../../models/tarif.dart';
import '../../widgets/section_placeholder.dart';

class NotesSection extends StatelessWidget {
  final Tarif tarif;

  const NotesSection({super.key, required this.tarif});

  @override
  Widget build(BuildContext context) {
    return SectionPlaceholder(
      icon: Icons.sticky_note_2_outlined,
      titre: 'Aucune note pour le moment',
      sousTitre: 'Notez les remarques d\'un client ou\nun rappel pour votre prochaine visite.',
      accent: tarif.accentGradient,
      actionLabel: 'Ajouter une note',
      onAction: () {},
    );
  }
}
