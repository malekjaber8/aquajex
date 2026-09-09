import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum RoleUtilisateur { admin, commercial }

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
    debugPrint('[Auth] deconnecter() appelé, currentUser=${_auth.currentUser?.email}');
    try {
      await _auth.signOut();
      debugPrint('[Auth] signOut() terminé, currentUser=${_auth.currentUser?.email}');
    } catch (e, st) {
      debugPrint('[Auth] signOut() a échoué: $e\n$st');
      rethrow;
    }
  }

  static Future<RoleUtilisateur> recupererRole(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = doc.data()?['role'] as String?;
    return role == 'admin' ? RoleUtilisateur.admin : RoleUtilisateur.commercial;
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
      }
    }
    return 'Échec de la connexion. Réessaie.';
  }
}
