class Note {
  final String id;
  final String contenu;
  final String? clientId;
  final String? clientNom;
  final DateTime date;
  final DateTime? dateRappel;

  const Note({
    required this.id,
    required this.contenu,
    this.clientId,
    this.clientNom,
    required this.date,
    this.dateRappel,
  });

  Note copyWith({
    String? contenu,
    String? clientId,
    String? clientNom,
    DateTime? dateRappel,
    bool effacerClient = false,
    bool effacerRappel = false,
  }) {
    return Note(
      id: id,
      contenu: contenu ?? this.contenu,
      clientId: effacerClient ? null : (clientId ?? this.clientId),
      clientNom: effacerClient ? null : (clientNom ?? this.clientNom),
      date: date,
      dateRappel: effacerRappel ? null : (dateRappel ?? this.dateRappel),
    );
  }
}
