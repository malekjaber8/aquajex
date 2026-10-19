// Écriture de fichiers sur le disque — indisponible sur le web (pas
// d'accès au système de fichiers), implémentée via dart:io ailleurs.
// Voir ExportPhotosService, seul utilisateur actuel.
export 'file_writer_stub.dart' if (dart.library.io) 'file_writer_io.dart';
