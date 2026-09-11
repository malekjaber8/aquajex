import 'package:flutter/material.dart';

import 'mode_prix.dart';

/// Taux de TVA appliqué aux factures (19%, taux standard en Tunisie).
const double tauxTvaFacture = 0.19;

/// Statut de suivi d'une commande/facture, modifiable après sa création
/// (depuis la liste des commandes).
enum StatutCommande {
  enAttente,
  confirmee,
  livree;

  static StatutCommande depuisNom(String? nom) {
    return StatutCommande.values.firstWhere(
      (s) => s.name == nom,
      orElse: () => StatutCommande.enAttente,
    );
  }

  String get libelle {
    switch (this) {
      case StatutCommande.enAttente:
        return 'En attente';
      case StatutCommande.confirmee:
        return 'Confirmée';
      case StatutCommande.livree:
        return 'Livrée';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutCommande.enAttente:
        return const Color(0xFFC9A24B);
      case StatutCommande.confirmee:
        return const Color(0xFF2C8FA0);
      case StatutCommande.livree:
        return const Color(0xFF2FAE60);
    }
  }
}

class LigneCommande {
  final String articleId;
  final String designation;
  final double prixUnitaire;
  final int quantite;
  final String? codeArticle;
  final String? codeBarre;
  final int? colisage;

  const LigneCommande({
    required this.articleId,
    required this.designation,
    required this.prixUnitaire,
    required this.quantite,
    this.codeArticle,
    this.codeBarre,
    this.colisage,
  });

  double get total => prixUnitaire * quantite;

  LigneCommande copyWith({int? quantite}) => LigneCommande(
    articleId: articleId,
    designation: designation,
    prixUnitaire: prixUnitaire,
    quantite: quantite ?? this.quantite,
    codeArticle: codeArticle,
    codeBarre: codeBarre,
    colisage: colisage,
  );

  Map<String, dynamic> versJson() => {
    'articleId': articleId,
    'designation': designation,
    'prixUnitaire': prixUnitaire,
    'quantite': quantite,
    'codeArticle': codeArticle,
    'codeBarre': codeBarre,
    'colisage': colisage,
  };

  factory LigneCommande.depuisJson(Map<String, dynamic> j) => LigneCommande(
    articleId: j['articleId'] as String,
    designation: j['designation'] as String,
    prixUnitaire: (j['prixUnitaire'] as num).toDouble(),
    quantite: j['quantite'] as int,
    codeArticle: j['codeArticle'] as String?,
    codeBarre: j['codeBarre'] as String?,
    colisage: j['colisage'] as int?,
  );
}

class Commande {
  final String id;
  final String clientId;
  final String clientNom;
  final DateTime date;
  final ModePrix modePrix;
  final List<LigneCommande> lignes;
  final String? note;

  /// Remise globale (en %) appliquée sur le total HT de la facture.
  final double remisePourcent;

  final StatutCommande statut;

  const Commande({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.date,
    required this.modePrix,
    required this.lignes,
    this.note,
    this.remisePourcent = 0,
    this.statut = StatutCommande.enAttente,
  });

  /// Total HT avant remise (prix unitaires × quantités).
  double get totalHt => lignes.fold(0, (s, l) => s + l.total);

  /// Alias conservé pour la compatibilité (utilisé comme total "brut").
  double get total => totalHt;

  double get remiseMontant => totalHt * (remisePourcent / 100);

  double get totalHtNet => totalHt - remiseMontant;

  double get montantTva => totalHtNet * tauxTvaFacture;

  double get totalTtc => totalHtNet + montantTva;

  int get nombreArticles => lignes.fold(0, (s, l) => s + l.quantite);

  Commande copyWith({
    String? clientId,
    String? clientNom,
    List<LigneCommande>? lignes,
    String? note,
    bool effacerNote = false,
    double? remisePourcent,
    StatutCommande? statut,
  }) => Commande(
    id: id,
    clientId: clientId ?? this.clientId,
    clientNom: clientNom ?? this.clientNom,
    date: date,
    modePrix: modePrix,
    lignes: lignes ?? this.lignes,
    note: effacerNote ? null : (note ?? this.note),
    remisePourcent: remisePourcent ?? this.remisePourcent,
    statut: statut ?? this.statut,
  );
}
