import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/note.dart';
import '../widgets/decorative_background.dart';

class NoteFormScreen extends StatefulWidget {
  final List<Color> accent;
  final List<Client> clients;
  final Note? noteExistante;

  const NoteFormScreen({
    super.key,
    required this.accent,
    required this.clients,
    this.noteExistante,
  });

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contenuCtrl;
  Client? _clientLie;
  DateTime? _dateRappel;

  bool get _modification => widget.noteExistante != null;

  @override
  void initState() {
    super.initState();
    final n = widget.noteExistante;
    _contenuCtrl = TextEditingController(text: n?.contenu ?? '');
    _dateRappel = n?.dateRappel;
    if (n?.clientId != null) {
      for (final c in widget.clients) {
        if (c.id == n!.clientId) {
          _clientLie = c;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDateRappel() async {
    final maintenant = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _dateRappel ?? maintenant,
      firstDate: DateTime(maintenant.year - 1),
      lastDate: DateTime(maintenant.year + 3),
    );
    if (choisie != null) {
      setState(() => _dateRappel = choisie);
    }
  }

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;
    final note = Note(
      id:
          widget.noteExistante?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      contenu: _contenuCtrl.text.trim(),
      clientId: _clientLie?.id,
      clientNom: _clientLie?.nomAffichage,
      date: widget.noteExistante?.date ?? DateTime.now(),
      dateRappel: _dateRappel,
    );
    Navigator.of(context).pop(note);
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

  String _formaterDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
                      _modification ? 'Modifier la note' : 'Nouvelle note',
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
                          TextFormField(
                            controller: _contenuCtrl,
                            minLines: 4,
                            maxLines: 8,
                            decoration: _decorationChamp(
                              'Remarque ou rappel pour votre prochaine visite',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Champ requis'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Lier à un client (optionnel)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<Client?>(
                            initialValue: _clientLie,
                            decoration: _decorationChamp('Client'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<Client?>(
                                value: null,
                                child: Text('Aucun client'),
                              ),
                              for (final c in widget.clients)
                                DropdownMenuItem<Client?>(
                                  value: c,
                                  child: Text(
                                    c.nomAffichage,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _clientLie = v),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Rappel (optionnel)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _choisirDateRappel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 19,
                                    color: accent.last,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _dateRappel != null
                                        ? _formaterDate(_dateRappel!)
                                        : 'Choisir une date de rappel',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: _dateRappel != null
                                          ? const Color(0xFF1B3B5F)
                                          : Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_dateRappel != null)
                                    IconButton(
                                      onPressed: () =>
                                          setState(() => _dateRappel = null),
                                      icon: const Icon(Icons.close, size: 18),
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
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
                          : 'Ajouter la note',
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
}
