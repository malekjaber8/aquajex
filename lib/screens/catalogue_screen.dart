import 'package:flutter/material.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';

class CatalogueScreen extends StatelessWidget {
  final Tarif tarif;
  final ModePrix modePrix;

  const CatalogueScreen({
    super.key,
    required this.tarif,
    required this.modePrix,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catalogue ${tarif.nom}'),
      ),
      body: Center(
        child: Text(
          'Catalogue ${tarif.nom} — ${modePrix.libelle} — à venir',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
