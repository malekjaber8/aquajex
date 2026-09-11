import 'dart:convert';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/mode_prix.dart';
import '../models/note.dart';
import '../models/tarif.dart';
import 'database_service.dart';

/// Accès aux clients et commandes, propre à chaque tarif — même principe
/// que CatalogueRepository.
class GestionRepository {
  final Tarif tarif;

  GestionRepository(this.tarif);

  String get _tarifKey => tarif.name;

  // --- Clients ---

  Future<List<Client>> getClients() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'clients',
      where: 'tarif = ?',
      whereArgs: [_tarifKey],
    );
    final clients = rows.map(_versClient).toList();
    // Trié côté Dart (et non en SQL) car le nom à afficher dépend du type
    // de client (société vs particulier) — voir Client.nomAffichage.
    clients.sort(
      (a, b) =>
          a.nomAffichage.toLowerCase().compareTo(b.nomAffichage.toLowerCase()),
    );
    return clients;
  }

  Future<void> ajouterClient(Client client) async {
    final db = await DatabaseService.instance.database;
    await db.insert('clients', _versLigneClient(client));
  }

  Future<void> modifierClient(Client client) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'clients',
      _versLigneClient(client),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> supprimerClient(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _versLigneClient(Client c) => {
    'id': c.id,
    'tarif': _tarifKey,
    'type': c.type.name,
    'nom': c.nom,
    'prenom': c.prenom,
    'nom_societe': c.nomSociete,
    'responsable': c.responsable,
    'telephone': c.telephone,
    'adresse': c.adresse,
    'matricule_fiscal': c.matriculeFiscal,
    'cin': c.cin,
  };

  Client _versClient(Map<String, Object?> r) => Client(
    id: r['id'] as String,
    type: TypeClient.values.byName(r['type'] as String? ?? 'particulier'),
    nom: r['nom'] as String,
    prenom: r['prenom'] as String,
    nomSociete: r['nom_societe'] as String?,
    responsable: r['responsable'] as String?,
    telephone: r['telephone'] as String?,
    adresse: r['adresse'] as String?,
    matriculeFiscal: r['matricule_fiscal'] as String?,
    cin: r['cin'] as String?,
  );

  // --- Commandes ---

  Future<List<Commande>> getCommandes() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'commandes',
      where: 'tarif = ?',
      whereArgs: [_tarifKey],
      orderBy: 'date DESC',
    );
    return rows.map(_versCommande).toList();
  }

  Future<void> ajouterCommande(Commande commande) async {
    final db = await DatabaseService.instance.database;
    await db.insert('commandes', _versLigneCommande(commande));
  }

  Future<void> modifierCommande(Commande commande) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'commandes',
      _versLigneCommande(commande),
      where: 'id = ?',
      whereArgs: [commande.id],
    );
  }

  Future<void> supprimerCommande(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('commandes', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _versLigneCommande(Commande c) => {
    'id': c.id,
    'tarif': _tarifKey,
    'client_id': c.clientId,
    'client_nom': c.clientNom,
    'date': c.date.toIso8601String(),
    'mode_prix': c.modePrix.name,
    'lignes': jsonEncode(c.lignes.map((l) => l.versJson()).toList()),
    'note': c.note,
    'remise_pourcent': c.remisePourcent,
    'statut': c.statut.name,
  };

  Commande _versCommande(Map<String, Object?> r) => Commande(
    id: r['id'] as String,
    clientId: r['client_id'] as String,
    clientNom: r['client_nom'] as String,
    date: DateTime.parse(r['date'] as String),
    modePrix: ModePrix.values.byName(r['mode_prix'] as String),
    lignes: (jsonDecode(r['lignes'] as String) as List)
        .map((j) => LigneCommande.depuisJson(j as Map<String, dynamic>))
        .toList(),
    note: r['note'] as String?,
    remisePourcent: (r['remise_pourcent'] as num?)?.toDouble() ?? 0,
    statut: StatutCommande.depuisNom(r['statut'] as String?),
  );

  // --- Notes ---

  Future<List<Note>> getNotes() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'notes',
      where: 'tarif = ?',
      whereArgs: [_tarifKey],
      orderBy: 'date DESC',
    );
    return rows.map(_versNote).toList();
  }

  Future<void> ajouterNote(Note note) async {
    final db = await DatabaseService.instance.database;
    await db.insert('notes', _versLigneNote(note));
  }

  Future<void> modifierNote(Note note) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'notes',
      _versLigneNote(note),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> supprimerNote(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _versLigneNote(Note n) => {
    'id': n.id,
    'tarif': _tarifKey,
    'contenu': n.contenu,
    'client_id': n.clientId,
    'client_nom': n.clientNom,
    'date': n.date.toIso8601String(),
    'date_rappel': n.dateRappel?.toIso8601String(),
  };

  Note _versNote(Map<String, Object?> r) => Note(
    id: r['id'] as String,
    contenu: r['contenu'] as String,
    clientId: r['client_id'] as String?,
    clientNom: r['client_nom'] as String?,
    date: DateTime.parse(r['date'] as String),
    dateRappel: r['date_rappel'] != null
        ? DateTime.parse(r['date_rappel'] as String)
        : null,
  );

  /// Exporte clients + commandes de ce tarif en structure sérialisable JSON.
  Future<Map<String, dynamic>> exporterDonnees() async {
    final clients = await getClients();
    final commandes = await getCommandes();
    return {
      'clients': clients
          .map(
            (c) => {
              'id': c.id,
              'type': c.type.name,
              'nom': c.nom,
              'prenom': c.prenom,
              'nomSociete': c.nomSociete,
              'responsable': c.responsable,
              'telephone': c.telephone,
              'adresse': c.adresse,
              'matriculeFiscal': c.matriculeFiscal,
              'cin': c.cin,
            },
          )
          .toList(),
      'commandes': commandes
          .map(
            (c) => {
              'id': c.id,
              'clientId': c.clientId,
              'clientNom': c.clientNom,
              'date': c.date.toIso8601String(),
              'modePrix': c.modePrix.name,
              'lignes': c.lignes.map((l) => l.versJson()).toList(),
              'note': c.note,
              'remisePourcent': c.remisePourcent,
              'statut': c.statut.name,
            },
          )
          .toList(),
    };
  }

  /// Remplace entièrement les clients et commandes de ce tarif par le
  /// contenu importé.
  Future<void> importerDonnees(Map<String, dynamic> data) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.delete('commandes', where: 'tarif = ?', whereArgs: [_tarifKey]);
      await txn.delete('clients', where: 'tarif = ?', whereArgs: [_tarifKey]);
      for (final brut in (data['clients'] as List? ?? const [])) {
        final m = brut as Map<String, dynamic>;
        await txn.insert('clients', {
          'id': m['id'],
          'tarif': _tarifKey,
          'type': m['type'] ?? 'particulier',
          'nom': m['nom'],
          'prenom': m['prenom'],
          'nom_societe': m['nomSociete'],
          'responsable': m['responsable'],
          'telephone': m['telephone'],
          'adresse': m['adresse'],
          'matricule_fiscal': m['matriculeFiscal'],
          'cin': m['cin'],
        });
      }
      for (final brut in (data['commandes'] as List? ?? const [])) {
        final m = brut as Map<String, dynamic>;
        await txn.insert('commandes', {
          'id': m['id'],
          'tarif': _tarifKey,
          'client_id': m['clientId'],
          'client_nom': m['clientNom'],
          'date': m['date'],
          'mode_prix': m['modePrix'],
          'lignes': jsonEncode(m['lignes']),
          'note': m['note'],
          'remise_pourcent': m['remisePourcent'] ?? 0,
          'statut': m['statut'] ?? 'enAttente',
        });
      }
    });
  }
}
