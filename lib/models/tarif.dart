import 'package:flutter/material.dart';

enum Tarif {
  aquajex,
  cinqFreres;

  String get nom {
    switch (this) {
      case Tarif.aquajex:
        return 'Aquajex';
      case Tarif.cinqFreres:
        return 'Les Cinq Frères';
    }
  }

  String get logoAsset {
    switch (this) {
      case Tarif.aquajex:
        return 'assets/images/logo_aquajex.jpg';
      case Tarif.cinqFreres:
        return 'assets/images/logo_cinq_freres.png';
    }
  }

  /// Couleurs d'accent propres à chaque marque (dégradé).
  List<Color> get accentGradient {
    switch (this) {
      case Tarif.aquajex:
        return const [Color(0xFF1B3B5F), Color(0xFFC9A24B)];
      case Tarif.cinqFreres:
        return const [Color(0xFF15495E), Color(0xFF2CA6A4)];
    }
  }

  Color get accentColor => accentGradient.last;
}
