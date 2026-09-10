import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/decorative_background.dart';

const _accent = [Color(0xFF1B3B5F), Color(0xFFC9A24B)];

/// Écran réservé à l'admin : création de comptes commerciaux et
/// consultation de la liste de ceux déjà créés.
///
/// La création se fait entièrement depuis l'app (voir
/// [AuthService.creerCompteCommercial]) ; la suppression/désactivation d'un
/// compte reste réservée à la console Firebase (pas de SDK Admin côté app).
class GestionCommerciauxScreen extends StatelessWidget {
  const GestionCommerciauxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 24, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    const Text(
                      'Comptes commerciaux',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: StreamBuilder<List<CompteCommercial>>(
                      stream: AuthService.streamComptesCommerciaux(),
                      builder: (context, snapshot) {
                        final comptes = snapshot.data ?? const [];
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          children: [
                            Text(
                              'Comptes existants',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black.withValues(alpha: 0.45),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                comptes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (comptes.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Aucun compte commercial pour le moment.',
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                ),
                              )
                            else
                              for (final compte in comptes) ...[
                                _CompteTile(compte: compte),
                                const SizedBox(height: 10),
                              ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaireCreation(context),
        backgroundColor: _accent.last,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          'Nouveau commercial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _ouvrirFormulaireCreation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormulaireCreationCompte(),
    );
  }
}

class _CompteTile extends StatelessWidget {
  final CompteCommercial compte;

  const _CompteTile({required this.compte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: _accent),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compte.nomComplet.isNotEmpty
                      ? compte.nomComplet
                      : compte.nomUtilisateur,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B5F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${compte.nomUtilisateur}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaireCreationCompte extends StatefulWidget {
  const _FormulaireCreationCompte();

  @override
  State<_FormulaireCreationCompte> createState() =>
      _FormulaireCreationCompteState();
}

class _FormulaireCreationCompteState extends State<_FormulaireCreationCompte> {
  final _formKey = GlobalKey<FormState>();
  final _nomCompletCtrl = TextEditingController();
  final _nomUtilisateurCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _motDePasseVisible = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nomCompletCtrl.dispose();
    _nomUtilisateurCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await AuthService.creerCompteCommercial(
        nomUtilisateur: _nomUtilisateurCtrl.text.trim(),
        motDePasse: _motDePasseCtrl.text,
        nomComplet: _nomCompletCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compte "${_nomUtilisateurCtrl.text.trim()}" créé avec succès.',
          ),
          backgroundColor: const Color(0xFF2FAE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = AuthService.messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nouveau compte commercial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3B5F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nomCompletCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Nom complet'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nomUtilisateurCtrl,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: _decoration('Nom d\'utilisateur'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ requis';
                      if (v.trim().contains(RegExp(r'\s'))) {
                        return 'Pas d\'espace dans le nom d\'utilisateur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _motDePasseCtrl,
                    obscureText: !_motDePasseVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _creer(),
                    decoration: _decoration('Mot de passe').copyWith(
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
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (v.length < 6) return '6 caractères minimum';
                      return null;
                    },
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13.5),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent.last,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _enCours ? null : _creer,
                      child: _enCours
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Créer le compte',
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
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accent.last, width: 1.6),
      ),
    );
  }
}
