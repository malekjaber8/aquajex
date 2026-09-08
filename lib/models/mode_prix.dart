enum ModePrix {
  detail,
  gros;

  String get libelle {
    switch (this) {
      case ModePrix.detail:
        return 'Prix détail';
      case ModePrix.gros:
        return 'Prix gros';
    }
  }

  String get libelleCourt {
    switch (this) {
      case ModePrix.detail:
        return 'Détail';
      case ModePrix.gros:
        return 'Gros';
    }
  }
}
