const _unites = [
  'ZERO', 'UN', 'DEUX', 'TROIS', 'QUATRE', 'CINQ', 'SIX', 'SEPT', 'HUIT',
  'NEUF', 'DIX', 'ONZE', 'DOUZE', 'TREIZE', 'QUATORZE', 'QUINZE', 'SEIZE', //
];

String _dizaines(int n) {
  if (n == 0) return '';
  if (n < 17) return _unites[n];
  if (n < 20) return 'DIX ${_unites[n - 10]}';
  final dizaine = n ~/ 10;
  final unite = n % 10;
  switch (dizaine) {
    case 2:
    case 3:
    case 4:
    case 5:
      const noms = {2: 'VINGT', 3: 'TRENTE', 4: 'QUARANTE', 5: 'CINQUANTE'};
      final base = noms[dizaine]!;
      if (unite == 0) return base;
      if (unite == 1) return '$base ET UN';
      return '$base ${_unites[unite]}';
    case 6:
      if (unite == 0) return 'SOIXANTE';
      if (unite == 1) return 'SOIXANTE ET UN';
      return 'SOIXANTE ${_unites[unite]}';
    case 7:
      if (unite == 1) return 'SOIXANTE ET ONZE';
      return 'SOIXANTE ${_dizaines(10 + unite)}';
    case 8:
      if (unite == 0) return 'QUATRE VINGTS';
      return 'QUATRE VINGT ${_unites[unite]}';
    case 9:
      return 'QUATRE VINGT ${_dizaines(10 + unite)}';
  }
  return '';
}

String _centaines(int n) {
  if (n == 0) return '';
  if (n < 100) return _dizaines(n);
  final centaines = n ~/ 100;
  final reste = n % 100;
  // Convention observée sur les factures de l'entreprise : "CENTS" garde
  // toujours son S au pluriel, même suivi d'un reste (contrairement à la
  // règle grammaticale stricte) — on reproduit ce style à l'identique.
  final mot = centaines == 1 ? 'CENT' : '${_unites[centaines]} CENTS';
  if (reste == 0) return mot;
  return '$mot ${_dizaines(reste)}';
}

/// Convertit un entier positif en lettres (français, majuscules, sans
/// tirets), à la manière des factures Tunisiennes.
String convertirEntierEnLettres(int n) {
  if (n == 0) return 'ZERO';
  final parts = <String>[];
  int reste = n;

  final milliards = reste ~/ 1000000000;
  reste %= 1000000000;
  final millions = reste ~/ 1000000;
  reste %= 1000000;
  final milliers = reste ~/ 1000;
  reste %= 1000;
  final unites = reste;

  if (milliards > 0) {
    parts.add(
      milliards == 1 ? 'UN MILLIARD' : '${_centaines(milliards)} MILLIARDS',
    );
  }
  if (millions > 0) {
    parts.add(
      millions == 1 ? 'UN MILLION' : '${_centaines(millions)} MILLIONS',
    );
  }
  if (milliers > 0) {
    parts.add(milliers == 1 ? 'MILLE' : '${_centaines(milliers)} MILLE');
  }
  if (unites > 0) {
    parts.add(_centaines(unites));
  }
  return parts.join(' ').trim();
}

/// Écrit un montant en dinars/millimes en toutes lettres, ex. 895.976 ->
/// "HUIT CENTS QUATRE VINGT QUINZE DINARS 976 MILLIMES".
String montantEnLettres(double montant) {
  final milliemes = (montant * 1000).round();
  final dinars = milliemes ~/ 1000;
  final reste = milliemes % 1000;
  final resteTexte = reste.toString().padLeft(3, '0');
  return '${convertirEntierEnLettres(dinars)} DINARS $resteTexte MILLIMES';
}
