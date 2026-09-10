import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'mode_prix.dart';

/// Statut d'affichage d'un article dans le catalogue : `normal` (aucun
/// bandeau), `promo` ou `nouveaute` (bandeau décoratif automatique sur la
/// carte, et filtre dédié dans le catalogue).
enum StatutArticle {
  normal,
  promo,
  nouveaute;

  static StatutArticle depuisNom(String? nom) {
    return StatutArticle.values.firstWhere(
      (s) => s.name == nom,
      orElse: () => StatutArticle.normal,
    );
  }

  String get libelle {
    switch (this) {
      case StatutArticle.normal:
        return 'Normal';
      case StatutArticle.promo:
        return 'Promo';
      case StatutArticle.nouveaute:
        return 'Nouveauté';
    }
  }

  IconData get icone {
    switch (this) {
      case StatutArticle.normal:
        return Icons.inventory_2_outlined;
      case StatutArticle.promo:
        return Icons.local_offer_outlined;
      case StatutArticle.nouveaute:
        return Icons.auto_awesome_outlined;
    }
  }

  /// Dégradé du bandeau affiché sur la carte article (null pour `normal`,
  /// qui n'affiche aucun bandeau).
  List<Color>? get degradeBandeau {
    switch (this) {
      case StatutArticle.normal:
        return null;
      case StatutArticle.promo:
        return const [Color(0xFFE53935), Color(0xFFB71C1C)];
      case StatutArticle.nouveaute:
        return const [Color(0xFF17A589), Color(0xFF0E6655)];
    }
  }
}

class Article {
  final String id;
  final String designation;
  final String categorie;
  final double prixDetail;
  final double prixGros;
  final String? codeArticle;
  final String? codeBarre;
  final String? taille;
  final int? colisage;
  final Uint8List? imageBytes;
  final StatutArticle statut;

  /// Anciens prix (avant remise), affichés barrés — uniquement pertinents
  /// pour un article en promo. Null = pas de prix barré à afficher.
  final double? prixDetailBarre;
  final double? prixGrosBarre;

  /// Disponibilité de l'article (badge affiché sur la carte).
  final bool disponible;

  const Article({
    required this.id,
    required this.designation,
    required this.categorie,
    required this.prixDetail,
    required this.prixGros,
    this.codeArticle,
    this.codeBarre,
    this.taille,
    this.colisage,
    this.imageBytes,
    this.statut = StatutArticle.normal,
    this.prixDetailBarre,
    this.prixGrosBarre,
    this.disponible = true,
  });

  double prixPour(ModePrix mode) =>
      mode == ModePrix.detail ? prixDetail : prixGros;

  double? prixBarrePour(ModePrix mode) =>
      mode == ModePrix.detail ? prixDetailBarre : prixGrosBarre;

  /// Pourcentage de remise arrondi (ex. 17 pour -17%), ou null si aucun
  /// prix barré n'est renseigné ou qu'il n'est pas supérieur au prix actuel.
  int? pourcentageRemisePour(ModePrix mode) {
    final barre = prixBarrePour(mode);
    final prix = prixPour(mode);
    if (barre == null || barre <= prix) return null;
    return (((barre - prix) / barre) * 100).round();
  }

  Article copyWith({
    String? designation,
    String? categorie,
    double? prixDetail,
    double? prixGros,
    String? codeArticle,
    String? codeBarre,
    String? taille,
    int? colisage,
    Uint8List? imageBytes,
    StatutArticle? statut,
    double? prixDetailBarre,
    bool effacerPrixDetailBarre = false,
    double? prixGrosBarre,
    bool effacerPrixGrosBarre = false,
    bool? disponible,
  }) {
    return Article(
      id: id,
      designation: designation ?? this.designation,
      categorie: categorie ?? this.categorie,
      prixDetail: prixDetail ?? this.prixDetail,
      prixGros: prixGros ?? this.prixGros,
      codeArticle: codeArticle ?? this.codeArticle,
      codeBarre: codeBarre ?? this.codeBarre,
      taille: taille ?? this.taille,
      colisage: colisage ?? this.colisage,
      imageBytes: imageBytes ?? this.imageBytes,
      statut: statut ?? this.statut,
      prixDetailBarre: effacerPrixDetailBarre
          ? null
          : (prixDetailBarre ?? this.prixDetailBarre),
      prixGrosBarre: effacerPrixGrosBarre
          ? null
          : (prixGrosBarre ?? this.prixGrosBarre),
      disponible: disponible ?? this.disponible,
    );
  }
}
