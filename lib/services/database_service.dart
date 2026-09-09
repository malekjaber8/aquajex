import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Ouvre (et crée si besoin) la base SQLite locale de l'application.
/// Fonctionne sur Android nativement, sur Windows/Linux via sqflite_ffi, et
/// sur le web via IndexedDB (sqflite_common_ffi_web) — chaque plateforme a
/// sa propre base locale.
///
/// Ne sert plus qu'aux clients/commandes/notes (données volontairement
/// locales à chaque appareil, jamais partagées) : le catalogue vit
/// désormais sur Firestore, voir [CatalogueRepository].
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _ouvrir();
    return _db!;
  }

  void _configurerFfiSiBesoin() {
    if (kIsWeb) {
      // Persistance réelle sur le web via IndexedDB (sqlite3 compilé en WASM),
      // pour que le catalogue survive aux rechargements de page.
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<String> _cheminFichier() async {
    if (kIsWeb) return 'aquajex.db';
    final dossier = await getDatabasesPath();
    return join(dossier, 'aquajex.db');
  }

  Future<Database> _ouvrir() async {
    _configurerFfiSiBesoin();
    final chemin = await _cheminFichier();

    return openDatabase(
      chemin,
      version: 2,
      onCreate: (db, version) async {
        await _creerTablesCatalogue(db);
        await _creerTablesGestion(db);
      },
      onUpgrade: (db, ancienneVersion, nouvelleVersion) async {
        if (ancienneVersion < 2) {
          await _creerTablesGestion(db);
        }
      },
    );
  }

  Future<void> _creerTablesCatalogue(Database db) async {
    await db.execute('''
      CREATE TABLE familles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarif TEXT NOT NULL,
        nom TEXT NOT NULL,
        UNIQUE(tarif, nom)
      )
    ''');
    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        tarif TEXT NOT NULL,
        categorie TEXT NOT NULL,
        designation TEXT NOT NULL,
        code_article TEXT,
        code_barre TEXT,
        taille TEXT,
        colisage INTEGER,
        prix_detail REAL NOT NULL,
        prix_gros REAL NOT NULL,
        image BLOB
      )
    ''');
  }

  Future<void> _creerTablesGestion(Database db) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        tarif TEXT NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        nom_societe TEXT,
        telephone TEXT,
        adresse TEXT,
        matricule_fiscal TEXT,
        cin TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE commandes (
        id TEXT PRIMARY KEY,
        tarif TEXT NOT NULL,
        client_id TEXT NOT NULL,
        client_nom TEXT NOT NULL,
        date TEXT NOT NULL,
        mode_prix TEXT NOT NULL,
        lignes TEXT NOT NULL
      )
    ''');
  }
}
