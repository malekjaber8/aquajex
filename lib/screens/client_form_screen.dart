import 'package:flutter/material.dart';

import '../models/client.dart';
import '../widgets/decorative_background.dart';

class ClientFormScreen extends StatefulWidget {
  final List<Color> accent;
  final Client? clientExistant;

  const ClientFormScreen({
    super.key,
    required this.accent,
    this.clientExistant,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TypeClient _type;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _societeCtrl;
  late final TextEditingController _responsableCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _matriculeCtrl;
  late final TextEditingController _cinCtrl;

  bool get _modification => widget.clientExistant != null;
  bool get _estSociete => _type == TypeClient.societe;

  @override
  void initState() {
    super.initState();
    final c = widget.clientExistant;
    _type = c?.type ?? TypeClient.particulier;
    _nomCtrl = TextEditingController(text: c?.nom ?? '');
    _prenomCtrl = TextEditingController(text: c?.prenom ?? '');
    _societeCtrl = TextEditingController(text: c?.nomSociete ?? '');
    _responsableCtrl = TextEditingController(text: c?.responsable ?? '');
    _telephoneCtrl = TextEditingController(text: c?.telephone ?? '');
    _adresseCtrl = TextEditingController(text: c?.adresse ?? '');
    _matriculeCtrl = TextEditingController(text: c?.matriculeFiscal ?? '');
    _cinCtrl = TextEditingController(text: c?.cin ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _societeCtrl.dispose();
    _responsableCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _matriculeCtrl.dispose();
    _cinCtrl.dispose();
    super.dispose();
  }

  String? _videVersNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;
    final client = Client(
      id:
          widget.clientExistant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      nom: _estSociete ? '' : _nomCtrl.text.trim(),
      prenom: _estSociete ? '' : _prenomCtrl.text.trim(),
      nomSociete: _estSociete ? _videVersNull(_societeCtrl.text) : null,
      responsable: _estSociete ? _videVersNull(_responsableCtrl.text) : null,
      telephone: _videVersNull(_telephoneCtrl.text),
      adresse: _videVersNull(_adresseCtrl.text),
      matriculeFiscal: _videVersNull(_matriculeCtrl.text),
      cin: _estSociete ? null : _videVersNull(_cinCtrl.text),
    );
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

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
                    Text(
                      _modification ? 'Modifier le client' : 'Nouveau client',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TypeClientToggle(
                            type: _type,
                            accent: accent,
                            onChanged: (type) => setState(() => _type = type),
                          ),
                          const SizedBox(height: 20),
                          if (_estSociete) ...[
                            _champTexte(
                              controller: _societeCtrl,
                              label: 'Nom de la société',
                              requis: true,
                            ),
                            const SizedBox(height: 16),
                            _champTexte(
                              controller: _responsableCtrl,
                              label: 'Responsable',
                            ),
                            const SizedBox(height: 16),
                            _champTexte(
                              controller: _telephoneCtrl,
                              label: 'Téléphone',
                              clavierNumerique: true,
                            ),
                            const SizedBox(height: 16),
                            _champTexte(
                              controller: _adresseCtrl,
                              label: 'Adresse',
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 24),
                            _champTexte(
                              controller: _matriculeCtrl,
                              label: 'Matricule fiscale',
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _champTexte(
                                    controller: _prenomCtrl,
                                    label: 'Prénom',
                                    requis: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _champTexte(
                                    controller: _nomCtrl,
                                    label: 'Nom',
                                    requis: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _champTexte(
                              controller: _telephoneCtrl,
                              label: 'Téléphone',
                              clavierNumerique: true,
                            ),
                            const SizedBox(height: 16),
                            _champTexte(
                              controller: _adresseCtrl,
                              label: 'Adresse',
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _champTexte(
                                    controller: _matriculeCtrl,
                                    label: 'Matricule fiscale',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _champTexte(
                                    controller: _cinCtrl,
                                    label: 'CIN',
                                    clavierNumerique: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: accent),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: accent.last.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _enregistrer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _modification
                          ? 'Enregistrer les modifications'
                          : 'Ajouter le client',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decorationChamp(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: widget.accent.last, width: 1.6),
      ),
    );
  }

  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    bool requis = false,
    bool clavierNumerique = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: clavierNumerique ? TextInputType.phone : TextInputType.text,
      decoration: _decorationChamp(label),
      validator: requis
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}

class _TypeClientToggle extends StatelessWidget {
  final TypeClient type;
  final List<Color> accent;
  final ValueChanged<TypeClient> onChanged;

  const _TypeClientToggle({
    required this.type,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _option(TypeClient.particulier, 'Particulier', Icons.person_outline),
          _option(TypeClient.societe, 'Société', Icons.apartment_outlined),
        ],
      ),
    );
  }

  Widget _option(TypeClient valeur, String label, IconData icon) {
    final selectionne = valeur == type;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(valeur),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selectionne ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selectionne
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selectionne ? accent.last : Colors.black45,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
                    color: selectionne
                        ? const Color(0xFF1B3B5F)
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
