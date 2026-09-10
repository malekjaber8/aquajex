enum TypeClient { particulier, societe }

class Client {
  final String id;
  final TypeClient type;
  final String nom;
  final String prenom;
  final String? nomSociete;
  final String? responsable;
  final String? telephone;
  final String? adresse;
  final String? matriculeFiscal;
  final String? cin;

  const Client({
    required this.id,
    this.type = TypeClient.particulier,
    this.nom = '',
    this.prenom = '',
    this.nomSociete,
    this.responsable,
    this.telephone,
    this.adresse,
    this.matriculeFiscal,
    this.cin,
  });

  bool get estSociete => type == TypeClient.societe;

  String get nomComplet => '$prenom $nom'.trim();

  /// Nom à afficher partout dans l'app (listes, panier, factures...) : celui
  /// de la société pour un client "société", prénom + nom sinon.
  String get nomAffichage =>
      estSociete ? (nomSociete ?? '').trim() : nomComplet;

  /// Initiales pour l'avatar (2 lettres), calculées différemment selon le
  /// type de client puisqu'une société n'a pas de prénom/nom.
  String get initiales {
    if (estSociete) {
      final mots = (nomSociete ?? '').trim().split(RegExp(r'\s+'));
      if (mots.isEmpty || mots.first.isEmpty) return '?';
      if (mots.length == 1) {
        return mots.first
            .substring(0, mots.first.length >= 2 ? 2 : 1)
            .toUpperCase();
      }
      return (mots[0][0] + mots[1][0]).toUpperCase();
    }
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    final initiales = '$p$n'.toUpperCase();
    return initiales.isEmpty ? '?' : initiales;
  }
}
