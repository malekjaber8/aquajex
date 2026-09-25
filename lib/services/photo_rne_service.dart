import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Prise de photo du RNE d'un client. Caméra sur tablette/téléphone/web,
/// sélecteur de fichier sur PC (pas de caméra fiable sur les builds bureau).
class PhotoRneService {
  PhotoRneService._();

  static const _largeurMax = 1600;
  static const _tailleMaxOctets = 700 * 1024;

  static bool get cameraDisponible =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Retourne la photo compressée en JPEG, ou null si l'utilisateur annule.
  /// Lève une [Exception] au message lisible si l'image est illisible ou
  /// reste trop lourde pour un document Firestore (limite 1 Mo, base64
  /// comprise).
  static Future<Uint8List?> capturer() async {
    final fichier = await ImagePicker().pickImage(
      source: cameraDisponible ? ImageSource.camera : ImageSource.gallery,
      maxWidth: _largeurMax.toDouble(),
      imageQuality: 80,
    );
    if (fichier == null) return null;
    return _traiter(await fichier.readAsBytes());
  }

  static Future<Uint8List> _traiter(Uint8List brut) async {
    final compresse = await compute(_compresser, brut);
    if (compresse == null) {
      throw Exception('Image illisible : choisis une photo (JPEG ou PNG).');
    }
    if (compresse.length > _tailleMaxOctets) {
      throw Exception(
        'Photo trop volumineuse même après compression '
        '(${(compresse.length / 1024).round()} Ko) : reprends-la de plus loin.',
      );
    }
    return compresse;
  }

  static Uint8List? _compresser(Uint8List brut) {
    img.Image? decodee;
    try {
      decodee = img.decodeImage(brut);
    } catch (_) {
      return null;
    }
    if (decodee == null) return null;
    Uint8List? dernier;
    for (final largeur in [_largeurMax, 1200, 900]) {
      final redimensionnee = decodee.width > largeur
          ? img.copyResize(decodee, width: largeur)
          : decodee;
      for (final qualite in [80, 65, 50]) {
        dernier = Uint8List.fromList(
          img.encodeJpg(redimensionnee, quality: qualite),
        );
        if (dernier.length <= _tailleMaxOctets) return dernier;
      }
    }
    return dernier;
  }
}
