import 'dart:typed_data';

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
    );
  }
}
