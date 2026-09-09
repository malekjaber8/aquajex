import 'dart:typed_data';
import 'package:flutter/material.dart';

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
  });

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
    );
  }
}
