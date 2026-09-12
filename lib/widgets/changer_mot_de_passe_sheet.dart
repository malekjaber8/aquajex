import 'package:flutter/material.dart';

import '../services/auth_service.dart';

const _accent = [Color(0xFF1B3B5F), Color(0xFFC9A24B)];

/// Ouvre la feuille "Changer mon mot de passe", accessible depuis n'importe
/// quel compte (admin ou commercial) sans passer par la console Firebase.
void afficherChangementMotDePasse(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FormulaireChangerMotDePasse(),
  );
}

class _FormulaireChangerMotDePasse extends StatefulWidget {
  const _FormulaireChangerMotDePasse();

  @override
  State<_FormulaireChangerMotDePasse> createState() =>
      _FormulaireChangerMotDePasseState();
}

class _FormulaireChangerMotDePasseState
    extends State<_FormulaireChangerMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _actuelCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();
  bool _actuelVisible = false;
  bool _nouveauVisible = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _actuelCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await AuthService.changerMotDePasse(
        motDePasseActuel: _actuelCtrl.text,
        nouveauMotDePasse: _nouveauCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe changé avec succès.'),
          backgroundColor: Color(0xFF2FAE60),
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
                    'Changer mon mot de passe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3B5F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _actuelCtrl,
                    obscureText: !_actuelVisible,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Mot de passe actuel').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _actuelVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _actuelVisible = !_actuelVisible),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nouveauCtrl,
                    obscureText: !_nouveauVisible,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Nouveau mot de passe').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _nouveauVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _nouveauVisible = !_nouveauVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (v.length < 6) return '6 caractères minimum';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmationCtrl,
                    obscureText: !_nouveauVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _valider(),
                    decoration: _decoration(
                      'Confirmer le nouveau mot de passe',
                    ),
                    validator: (v) {
                      if (v != _nouveauCtrl.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
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
                      onPressed: _enCours ? null : _valider,
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
                              'Changer le mot de passe',
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
