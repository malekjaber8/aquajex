class Client {
  final String id;
  final String nom;
  final String prenom;
  final String? nomSociete;
  final String? telephone;
  final String? adresse;
  final String? matriculeFiscal;
  final String? cin;

  const Client({
    required this.id,
    required this.nom,
    required this.prenom,
    this.nomSociete,
    this.telephone,
    this.adresse,
    this.matriculeFiscal,
    this.cin,
  });

  String get nomComplet => '$prenom $nom'.trim();
}
