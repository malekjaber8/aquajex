import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/article.dart';
import '../models/tarif.dart';

/// Un article accompagné du tarif (catalogue) auquel il appartient — utilisé
/// pour les rubans promo/nouveauté de l'écran d'accueil, qui mélangent les
/// articles des deux catalogues.
class ArticleAvecTarif {
  final Article article;
  final Tarif tarif;

  const ArticleAvecTarif({required this.article, required this.tarif});
}

/// Accès aux familles et articles, propre à chaque tarif (Aquajex / Les
/// Cinq Frères ont chacun leur propre catalogue).
///
/// Le catalogue est la seule donnée partagée entre appareils : il vit sur
/// Firestore (base de données en ligne) et se synchronise en direct entre
/// le PC (admin, qui peut modifier) et la tablette du commercial (lecture
/// seule). Les clients/commandes/notes restent volontairement en dehors de
/// ce repository : ils ne sont jamais partagés (voir GestionRepository).
class CatalogueRepository {
  final Tarif tarif;

  CatalogueRepository(this.tarif);

  String get _tarifKey => tarif.name;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _famillesRef =>
      _db.collection('familles');

  CollectionReference<Map<String, dynamic>> get _articlesRef =>
      _db.collection('articles');

  /// Flux en direct des familles de ce tarif, toujours triées par nom.
  Stream<List<String>> streamFamilles() {
    return _famillesRef
        .where('tarif', isEqualTo: _tarifKey)
        .snapshots()
        .map((snap) {
      final noms = snap.docs.map((d) => d.data()['nom'] as String).toList();
      noms.sort();
      return noms;
    });
  }

  /// Flux en direct des articles de ce tarif, toujours triés par désignation.
  Stream<List<Article>> streamArticles() {
    return _articlesRef
        .where('tarif', isEqualTo: _tarifKey)
        .snapshots()
        .map((snap) {
      final articles = snap.docs
          .map((d) => _versArticle({...d.data(), 'id': d.id}))
          .toList();
      articles.sort((a, b) => a.designation.compareTo(b.designation));
      return articles;
    });
  }

  /// Flux en direct (tous tarifs confondus) des articles ayant un statut
  /// donné — utilisé par les rubans promo/nouveauté de l'écran d'accueil.
  static Stream<List<ArticleAvecTarif>> streamArticlesParStatut(
      StatutArticle statut) {
    return FirebaseFirestore.instance
        .collection('articles')
        .where('statut', isEqualTo: statut.name)
        .snapshots()
        .map((snap) {
      final resultats = snap.docs.map((d) {
        final data = {...d.data(), 'id': d.id};
        final tarif = Tarif.values.firstWhere(
          (t) => t.name == data['tarif'],
          orElse: () => Tarif.aquajex,
        );
        return ArticleAvecTarif(article: _versArticle(data), tarif: tarif);
      }).toList();
      resultats.sort(
          (a, b) => a.article.designation.compareTo(b.article.designation));
      return resultats;
    });
  }

  String _idFamille(String nom) => '${_tarifKey}__$nom';

  Future<void> ajouterFamille(String nom) async {
    await _famillesRef
        .doc(_idFamille(nom))
        .set({'tarif': _tarifKey, 'nom': nom});
  }

  Future<void> renommerFamille(String ancienNom, String nouveauNom) async {
    final batch = _db.batch();
    batch.delete(_famillesRef.doc(_idFamille(ancienNom)));
    batch.set(_famillesRef.doc(_idFamille(nouveauNom)),
        {'tarif': _tarifKey, 'nom': nouveauNom});

    final articles = await _articlesRef
        .where('tarif', isEqualTo: _tarifKey)
        .where('categorie', isEqualTo: ancienNom)
        .get();
    for (final doc in articles.docs) {
      batch.update(doc.reference, {'categorie': nouveauNom});
    }
    await batch.commit();
  }

  Future<void> supprimerFamille(String nom) async {
    final batch = _db.batch();
    batch.delete(_famillesRef.doc(_idFamille(nom)));

    final articles = await _articlesRef
        .where('tarif', isEqualTo: _tarifKey)
        .where('categorie', isEqualTo: nom)
        .get();
    for (final doc in articles.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> ajouterArticle(Article article) async {
    await _articlesRef.doc(article.id).set(_versDocument(article));
  }

  Future<void> modifierArticle(Article article) async {
    await _articlesRef.doc(article.id).set(_versDocument(article));
  }

  Future<void> supprimerArticle(String id) async {
    await _articlesRef.doc(id).delete();
  }

  Map<String, dynamic> _versDocument(Article a) => {
        'tarif': _tarifKey,
        'categorie': a.categorie,
        'designation': a.designation,
        'codeArticle': a.codeArticle,
        'codeBarre': a.codeBarre,
        'taille': a.taille,
        'colisage': a.colisage,
        'prixDetail': a.prixDetail,
        'prixGros': a.prixGros,
        'image': a.imageBytes != null ? base64Encode(a.imageBytes!) : null,
        'statut': a.statut.name,
      };

  static Article _versArticle(Map<String, dynamic> d) => Article(
        id: d['id'] as String? ?? '',
        categorie: d['categorie'] as String? ?? '',
        designation: d['designation'] as String? ?? '',
        statut: StatutArticle.depuisNom(d['statut'] as String?),
        codeArticle: d['codeArticle'] as String?,
        codeBarre: d['codeBarre'] as String?,
        taille: d['taille'] as String?,
        colisage: d['colisage'] as int?,
        prixDetail: (d['prixDetail'] as num?)?.toDouble() ?? 0,
        prixGros: (d['prixGros'] as num?)?.toDouble() ?? 0,
        imageBytes:
            d['image'] != null ? base64Decode(d['image'] as String) : null,
      );
}
