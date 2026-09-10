import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/decorative_background.dart';

const _accent = [Color(0xFF1B3B5F), Color(0xFFC9A24B)];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;
  bool _connexionEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nomController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    final nom = _nomController.text.trim();
    final motDePasse = _motDePasseController.text;
    if (nom.isEmpty || motDePasse.isEmpty) {
      setState(
        () => _erreur = 'Renseigne ton nom d\'utilisateur et ton mot de passe.',
      );
      return;
    }
    setState(() {
      _connexionEnCours = true;
      _erreur = null;
    });
    try {
      await AuthService.connecter(nom, motDePasse);
      // La navigation se fait automatiquement via le StreamBuilder de AuthGate.
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = AuthService.messageErreur(e));
    } finally {
      if (mounted) setState(() => _connexionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: _accent),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Aquajex Catalogue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3B5F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connecte-toi pour continuer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _nomController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _motDePasseController,
                        obscureText: !_motDePasseVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _connecter(),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _motDePasseVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _motDePasseVisible = !_motDePasseVisible,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _erreur!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent.last,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _connexionEnCours ? null : _connecter,
                          child: _connexionEnCours
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
