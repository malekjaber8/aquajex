import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/mode_prix.dart';
import '../models/note.dart';
import '../models/tarif.dart';

/// Accès aux clients, commandes et notes, propre à chaque tarif.
///
/// Les trois vivent sur Firestore, propres au compte connecté (voir
/// `ownerUid` + firestore.rules) : chacun ne voit que ce qu'il a créé, et
/// l'admin peut consulter le travail d'un commercial en se connectant
/// simplement avec son compte.
class GestionRepository {
  final Tarif tarif;

  GestionRepository(this.tarif);

  String get _tarifKey => tarif.name;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _ownerUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _db.collection('clients');

  CollectionReference<Map<String, dynamic>> get _commandesRef =>
      _db.collection('commandes');

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('notes');

  // --- Clients ---

  Future<List<Client>> getClients() async {
    final snap = await _clientsRef
        .where('ownerUid', isEqualTo: _ownerUid)
        .where('tarif', isEqualTo: _tarifKey)
        .get();
    final clients = snap.docs
        .map((d) => _versClient({...d.data(), 'id': d.id}))
        .toList();
    // Trié côté Dart (et non en requête) car le nom à afficher dépend du
    // type de client (société vs particulier) — voir Client.nomAffichage.
    clients.sort(
      (a, b) =>
          a.nomAffichage.toLowerCase().compareTo(b.nomAffichage.toLowerCase()),
    );
    return clients;
  }

  Future<void> ajouterClient(Client client) async {
    await _clientsRef.doc(client.id).set(_versDocumentClient(client));
  }

  Future<void> modifierClient(Client client) async {
    await _clientsRef.doc(client.id).set(_versDocumentClient(client));
  }

  Future<void> supprimerClient(String id) async {
    await _clientsRef.doc(id).delete();
  }

  Map<String, dynamic> _versDocumentClient(Client c) => {
    'ownerUid': _ownerUid,
    'tarif': _tarifKey,
    'type': c.type.name,
    'nom': c.nom,
    'prenom': c.prenom,
    'nomSociete': c.nomSociete,
    'responsable': c.responsable,
    'telephone': c.telephone,
    'adresse': c.adresse,
    'matriculeFiscal': c.matriculeFiscal,
    'cin': c.cin,
  };

  Client _versClient(Map<String, dynamic> d) => Client(
    id: d['id'] as String,
    type: TypeClient.values.byName(d['type'] as String? ?? 'particulier'),
    nom: d['nom'] as String? ?? '',
    prenom: d['prenom'] as String? ?? '',
    nomSociete: d['nomSociete'] as String?,
    responsable: d['responsable'] as String?,
    telephone: d['telephone'] as String?,
    adresse: d['adresse'] as String?,
    matriculeFiscal: d['matriculeFiscal'] as String?,
    cin: d['cin'] as String?,
  );

  // --- Commandes ---

  Future<List<Commande>> getCommandes() async {
    final snap = await _commandesRef
        .where('ownerUid', isEqualTo: _ownerUid)
        .where('tarif', isEqualTo: _tarifKey)
        .get();
    final commandes = snap.docs
        .map((d) => _versCommande({...d.data(), 'id': d.id}))
        .toList();
    commandes.sort((a, b) => b.date.compareTo(a.date));
    return commandes;
  }

  Future<void> ajouterCommande(Commande commande) async {
    await _commandesRef.doc(commande.id).set(_versDocumentCommande(commande));
  }

  Future<void> modifierCommande(Commande commande) async {
    await _commandesRef.doc(commande.id).set(_versDocumentCommande(commande));
  }

  Future<void> supprimerCommande(String id) async {
    await _commandesRef.doc(id).delete();
  }

  Map<String, dynamic> _versDocumentCommande(Commande c) => {
    'ownerUid': _ownerUid,
    'tarif': _tarifKey,
    'clientId': c.clientId,
    'clientNom': c.clientNom,
    'date': c.date.toIso8601String(),
    'modePrix': c.modePrix.name,
    'lignes': c.lignes.map((l) => l.versJson()).toList(),
    'note': c.note,
    'remisePourcent': c.remisePourcent,
    'statut': c.statut.name,
  };

  Commande _versCommande(Map<String, dynamic> d) => Commande(
    id: d['id'] as String,
    clientId: d['clientId'] as String,
    clientNom: d['clientNom'] as String,
    date: DateTime.parse(d['date'] as String),
    modePrix: ModePrix.values.byName(d['modePrix'] as String),
    lignes: ((d['lignes'] as List?) ?? const [])
        .map(
          (j) => LigneCommande.depuisJson(Map<String, dynamic>.from(j as Map)),
        )
        .toList(),
    note: d['note'] as String?,
    remisePourcent: (d['remisePourcent'] as num?)?.toDouble() ?? 0,
    statut: StatutCommande.depuisNom(d['statut'] as String?),
  );

  // --- Notes ---

  Future<List<Note>> getNotes() async {
    final snap = await _notesRef
        .where('ownerUid', isEqualTo: _ownerUid)
        .where('tarif', isEqualTo: _tarifKey)
        .get();
    final notes = snap.docs
        .map((d) => _versNote({...d.data(), 'id': d.id}))
        .toList();
    notes.sort((a, b) => b.date.compareTo(a.date));
    return notes;
  }

  Future<void> ajouterNote(Note note) async {
    await _notesRef.doc(note.id).set(_versDocumentNote(note));
  }

  Future<void> modifierNote(Note note) async {
    await _notesRef.doc(note.id).set(_versDocumentNote(note));
  }

  Future<void> supprimerNote(String id) async {
    await _notesRef.doc(id).delete();
  }

  Map<String, dynamic> _versDocumentNote(Note n) => {
    'ownerUid': _ownerUid,
    'tarif': _tarifKey,
    'contenu': n.contenu,
    'clientId': n.clientId,
    'clientNom': n.clientNom,
    'date': n.date.toIso8601String(),
    'dateRappel': n.dateRappel?.toIso8601String(),
  };

  Note _versNote(Map<String, dynamic> d) => Note(
    id: d['id'] as String,
    contenu: d['contenu'] as String,
    clientId: d['clientId'] as String?,
    clientNom: d['clientNom'] as String?,
    date: DateTime.parse(d['date'] as String),
    dateRappel: d['dateRappel'] != null
        ? DateTime.parse(d['dateRappel'] as String)
        : null,
  );

  /// Exporte clients + commandes de ce tarif (compte connecté) en structure
  /// sérialisable JSON.
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

  /// Remplace entièrement les clients et commandes de ce tarif (compte
  /// connecté) par le contenu importé.
  Future<void> importerDonnees(Map<String, dynamic> data) async {
    final anciens = await Future.wait([getClients(), getCommandes()]);
    final batch = _db.batch();
    for (final c in anciens[0] as List<Client>) {
      batch.delete(_clientsRef.doc(c.id));
    }
    for (final c in anciens[1] as List<Commande>) {
      batch.delete(_commandesRef.doc(c.id));
    }
    for (final brut in (data['clients'] as List? ?? const [])) {
      final m = brut as Map<String, dynamic>;
      batch.set(
        _clientsRef.doc(m['id'] as String),
        _versDocumentClient(
          Client(
            id: m['id'] as String,
            type: TypeClient.values.byName(
              m['type'] as String? ?? 'particulier',
            ),
            nom: m['nom'] as String? ?? '',
            prenom: m['prenom'] as String? ?? '',
            nomSociete: m['nomSociete'] as String?,
            responsable: m['responsable'] as String?,
            telephone: m['telephone'] as String?,
            adresse: m['adresse'] as String?,
            matriculeFiscal: m['matriculeFiscal'] as String?,
            cin: m['cin'] as String?,
          ),
        ),
      );
    }
    for (final brut in (data['commandes'] as List? ?? const [])) {
      final m = brut as Map<String, dynamic>;
      batch.set(
        _commandesRef.doc(m['id'] as String),
        _versDocumentCommande(
          Commande(
            id: m['id'] as String,
            clientId: m['clientId'] as String,
            clientNom: m['clientNom'] as String,
            date: DateTime.parse(m['date'] as String),
            modePrix: ModePrix.values.byName(m['modePrix'] as String),
            lignes: ((m['lignes'] as List?) ?? const [])
                .map((j) => LigneCommande.depuisJson(j as Map<String, dynamic>))
                .toList(),
            note: m['note'] as String?,
            remisePourcent: (m['remisePourcent'] as num?)?.toDouble() ?? 0,
            statut: StatutCommande.depuisNom(m['statut'] as String?),
          ),
        ),
      );
    }
    await batch.commit();
  }
}
