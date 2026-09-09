import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/tarif_selection_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AquajexApp());
}

class AquajexApp extends StatelessWidget {
  const AquajexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalogue Commercial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B5F)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const AuthGate(),
    );
  }
}

/// Affiche l'écran de connexion tant que personne n'est identifié, puis
/// bascule automatiquement vers l'app une fois connecté — sans rien de
/// plus à faire, la déconnexion (bouton dans l'app) revient ici aussi.
///
/// Firebase Auth restaure automatiquement la session précédente à chaque
/// démarrage de l'app ; comme on veut au contraire imposer une reconnexion
/// à chaque lancement, on coupe cette toute première session restaurée dès
/// qu'elle apparaît dans le flux (un simple `signOut()` avant `runApp()`
/// est trop tôt : sur desktop, la restauration de session est asynchrone
/// et arrive après, ce qui annulerait la déconnexion).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _premierEtatTraite = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.changementsUtilisateur,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final utilisateur = snapshot.data;

        if (!_premierEtatTraite) {
          _premierEtatTraite = true;
          if (utilisateur != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AuthService.deconnecter();
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }

        if (utilisateur == null) {
          return const LoginScreen();
        }
        return FutureBuilder<RoleUtilisateur>(
          future: AuthService.recupererRole(utilisateur.uid),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return TarifSelectionScreen(
              isAdmin: roleSnapshot.data == RoleUtilisateur.admin,
            );
          },
        );
      },
    );
  }
}
