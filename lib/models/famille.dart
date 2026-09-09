import 'package:flutter/material.dart';

/// Icône représentative pour une famille d'articles, avec une valeur
/// par défaut pour les noms non reconnus.
IconData iconePourFamille(String nom) {
  switch (nom.toLowerCase()) {
    case 'pompes':
      return Icons.water_drop_outlined;
    case 'filtration':
      return Icons.filter_alt_outlined;
    case 'robinetterie':
      return Icons.plumbing_outlined;
    case 'accessoires':
      return Icons.build_outlined;
    case 'éclairage':
      return Icons.lightbulb_outline;
    case 'traitement':
      return Icons.science_outlined;
    default:
      return Icons.category_outlined;
  }
}
