import 'dart:io';

Future<void> ecrireFichier(String chemin, List<int> octets) async {
  final fichier = File(chemin);
  await fichier.create(recursive: true);
  await fichier.writeAsBytes(octets);
}
