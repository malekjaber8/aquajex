import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/tarif.dart';
import 'catalogue_repository.dart';
import 'file_writer.dart';

/// Résultat d'un export de photos du catalogue, affiché à l'admin après
/// coup (voir [ExportPhotosService.exporter]).
class ResultatExportPhotos {
  final String dossier;
  final int nombrePhotos;
  final int nombreArticlesSansPhoto;

  const ResultatExportPhotos({
    required this.dossier,
    required this.nombrePhotos,
    required this.nombreArticlesSansPhoto,
  });
}

/// Enregistre sur le disque (PC admin uniquement, pas disponible sur le
/// web) toutes les photos d'articles déjà présentes dans Firestore, une
/// par une, classées par tarif puis par famille — pour pouvoir ensuite les
/// réutiliser ailleurs (ex. le site vitrine public) sans ressaisir de mot
/// de passe ni toucher à Firestore directement : on se contente de lire ce
/// que l'admin, déjà connecté dans l'appli, a le droit de lire.
class ExportPhotosService {
  ExportPhotosService._();

  static Future<ResultatExportPhotos?> exporter() async {
    final dossier = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisir où enregistrer les photos du catalogue',
    );
    if (dossier == null) return null;

    var nombrePhotos = 0;
    var sansPhoto = 0;

    for (final tarif in Tarif.values) {
      final articles = await CatalogueRepository(tarif).streamArticles().first;
      for (final article in articles) {
        final octets = article.imageBytes;
        if (octets == null) {
          sansPhoto++;
          continue;
        }
        final sousDossier = _nomSur(
          article.categorie.isEmpty ? 'Sans famille' : article.categorie,
        );
        final nomFichier = _nomSur(
          '${article.codeArticle ?? article.id}_${article.designation}',
        );
        final chemin =
            '$dossier/${tarif.name}/$sousDossier/$nomFichier${_extensionPour(octets)}';
        await ecrireFichier(chemin, octets);
        nombrePhotos++;
      }
    }

    return ResultatExportPhotos(
      dossier: dossier,
      nombrePhotos: nombrePhotos,
      nombreArticlesSansPhoto: sansPhoto,
    );
  }

  /// Nettoie un texte libre pour en faire un nom de fichier/dossier sûr.
  static String _nomSur(String s) {
    final nettoye = s
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    if (nettoye.isEmpty) return 'sans_nom';
    return nettoye.length > 80 ? nettoye.substring(0, 80) : nettoye;
  }

  /// Les images sont stockées telles qu'importées (pas toujours du JPEG) :
  /// on détecte le format via les octets magiques plutôt que de supposer.
  static String _extensionPour(Uint8List octets) {
    final estPng =
        octets.length >= 8 &&
        octets[0] == 0x89 &&
        octets[1] == 0x50 &&
        octets[2] == 0x4E &&
        octets[3] == 0x47;
    return estPng ? '.png' : '.jpg';
  }
}
