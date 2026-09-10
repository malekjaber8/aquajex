import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum RoleUtilisateur { admin, commercial }

/// Fiche d'un compte commercial (issue de Firestore `users/{uid}`), pour
/// l'écran de gestion réservé à l'admin.
class CompteCommercial {
  final String uid;
  final String nomUtilisateur;
  final String nomComplet;

  const CompteCommercial({
    required this.uid,
    required this.nomUtilisateur,
    required this.nomComplet,
  });

  factory CompteCommercial.depuisDocument(
    String uid,
    Map<String, dynamic> data,
  ) {
    return CompteCommercial(
      uid: uid,
      nomUtilisateur: data['nomUtilisateur'] as String? ?? '',
      nomComplet: data['nomComplet'] as String? ?? '',
    );
  }
}

/// Connexion par nom d'utilisateur + mot de passe.
///
/// Firebase Authentication ne connaît que des adresses e-mail : on
/// transforme donc silencieusement le nom d'utilisateur saisi en une
/// adresse technique (jamais affichée, jamais un vrai e-mail) pour
/// que l'utilisateur n'ait jamais à s'en soucier.
class AuthService {
  static const _domaine = '@aquajex.local';

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static Stream<User?> get changementsUtilisateur => _auth.authStateChanges();

  static User? get utilisateurActuel => _auth.currentUser;

  static String _versEmail(String nomUtilisateur) =>
      '${nomUtilisateur.trim().toLowerCase()}$_domaine';

  static Future<void> connecter(String nomUtilisateur, String motDePasse) {
    return _auth.signInWithEmailAndPassword(
      email: _versEmail(nomUtilisateur),
      password: motDePasse,
    );
  }

  static Future<void> deconnecter() async {
    debugPrint(
      '[Auth] deconnecter() appelé, currentUser=${_auth.currentUser?.email}',
    );
    try {
      await _auth.signOut();
      debugPrint(
        '[Auth] signOut() terminé, currentUser=${_auth.currentUser?.email}',
      );
    } catch (e, st) {
      debugPrint('[Auth] signOut() a échoué: $e\n$st');
      rethrow;
    }
  }

  static Future<RoleUtilisateur> recupererRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = doc.data()?['role'] as String?;
    return role == 'admin' ? RoleUtilisateur.admin : RoleUtilisateur.commercial;
  }

  /// Flux des comptes commerciaux (fiches Firestore `users` de rôle
  /// "commercial"), pour l'écran de gestion réservé à l'admin.
  static Stream<List<CompteCommercial>> streamComptesCommerciaux() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'commercial')
        .snapshots()
        .map((snap) {
          final comptes = snap.docs
              .map((d) => CompteCommercial.depuisDocument(d.id, d.data()))
              .toList();
          comptes.sort((a, b) => a.nomUtilisateur.compareTo(b.nomUtilisateur));
          return comptes;
        });
  }

  /// Crée un nouveau compte commercial (Firebase Auth + fiche Firestore)
  /// sans déconnecter l'admin actuellement connecté.
  ///
  /// Le SDK Firebase Auth connecte automatiquement tout compte qu'il vient
  /// de créer sur l'instance utilisée : pour éviter de déconnecter l'admin
  /// en pleine création, on passe par une seconde application Firebase
  /// (même projet, instance Auth indépendante) dédiée à cette opération.
  static Future<void> creerCompteCommercial({
    required String nomUtilisateur,
    required String motDePasse,
    required String nomComplet,
  }) async {
    FirebaseApp appSecondaire;
    try {
      appSecondaire = Firebase.app('creationCommercial');
    } catch (_) {
      appSecondaire = await Firebase.initializeApp(
        name: 'creationCommercial',
        options: Firebase.app().options,
      );
    }
    final authSecondaire = FirebaseAuth.instanceFor(app: appSecondaire);
    try {
      final identifiants = await authSecondaire.createUserWithEmailAndPassword(
        email: _versEmail(nomUtilisateur),
        password: motDePasse,
      );
      final uid = identifiants.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'commercial',
        'nomUtilisateur': nomUtilisateur.trim().toLowerCase(),
        'nomComplet': nomComplet.trim(),
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } finally {
      await authSecondaire.signOut();
    }
  }

  /// Traduit une exception Firebase Auth en message compréhensible en
  /// français pour l'utilisateur final.
  static String messageErreur(Object erreur) {
    if (erreur is FirebaseAuthException) {
      switch (erreur.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
        case 'invalid-email':
          return 'Nom d\'utilisateur ou mot de passe incorrect.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives, réessaie dans quelques minutes.';
        case 'network-request-failed':
          return 'Pas de connexion internet.';
        case 'email-already-in-use':
          return 'Ce nom d\'utilisateur est déjà pris.';
        case 'weak-password':
          return 'Mot de passe trop court (6 caractères minimum).';
      }
    }
    return 'Échec de l\'opération. Réessaie.';
  }
}
