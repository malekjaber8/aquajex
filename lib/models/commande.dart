import 'mode_prix.dart';

class LigneCommande {
  final String articleId;
  final String designation;
  final double prixUnitaire;
  final int quantite;

  const LigneCommande({
    required this.articleId,
    required this.designation,
    required this.prixUnitaire,
    required this.quantite,
  });

  double get total => prixUnitaire * quantite;

  LigneCommande copyWith({int? quantite}) => LigneCommande(
        articleId: articleId,
        designation: designation,
        prixUnitaire: prixUnitaire,
        quantite: quantite ?? this.quantite,
      );

  Map<String, dynamic> versJson() => {
        'articleId': articleId,
        'designation': designation,
        'prixUnitaire': prixUnitaire,
        'quantite': quantite,
      };

  factory LigneCommande.depuisJson(Map<String, dynamic> j) => LigneCommande(
        articleId: j['articleId'] as String,
        designation: j['designation'] as String,
        prixUnitaire: (j['prixUnitaire'] as num).toDouble(),
        quantite: j['quantite'] as int,
      );
}

class Commande {
  final String id;
  final String clientId;
  final String clientNom;
  final DateTime date;
  final ModePrix modePrix;
  final List<LigneCommande> lignes;

  const Commande({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.date,
    required this.modePrix,
    required this.lignes,
  });

  double get total => lignes.fold(0, (s, l) => s + l.total);

  int get nombreArticles => lignes.fold(0, (s, l) => s + l.quantite);

  Commande copyWith({
    String? clientId,
    String? clientNom,
    List<LigneCommande>? lignes,
  }) =>
      Commande(
        id: id,
        clientId: clientId ?? this.clientId,
        clientNom: clientNom ?? this.clientNom,
        date: date,
        modePrix: modePrix,
        lignes: lignes ?? this.lignes,
      );
}
