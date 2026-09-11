import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/article.dart';
import '../widgets/decorative_background.dart';

class ArticleFormScreen extends StatefulWidget {
  final List<Color> accent;
  final List<String> famillesExistantes;
  final String? familleInitiale;
  final Article? articleExistant;

  const ArticleFormScreen({
    super.key,
    required this.accent,
    required this.famillesExistantes,
    this.familleInitiale,
    this.articleExistant,
  });

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _designationCtrl;
  late final TextEditingController _codeArticleCtrl;
  late final TextEditingController _codeBarreCtrl;
  late final TextEditingController _tailleCtrl;
  late final TextEditingController _colisageCtrl;
  late final TextEditingController _prixDetailCtrl;
  late final TextEditingController _prixGrosCtrl;
  late final TextEditingController _prixDetailBarreCtrl;
  late final TextEditingController _prixGrosBarreCtrl;

  String? _familleChoisie;
  Uint8List? _imageBytes;
  late StatutArticle _statut;
  late bool _disponible;

  bool get _modification => widget.articleExistant != null;

  @override
  void initState() {
    super.initState();
    final a = widget.articleExistant;
    _designationCtrl = TextEditingController(text: a?.designation ?? '');
    _codeArticleCtrl = TextEditingController(text: a?.codeArticle ?? '');
    _codeBarreCtrl = TextEditingController(text: a?.codeBarre ?? '');
    _tailleCtrl = TextEditingController(text: a?.taille ?? '');
    _colisageCtrl = TextEditingController(text: a?.colisage?.toString() ?? '');
    _prixDetailCtrl = TextEditingController(
      text: a?.prixDetail.toStringAsFixed(3) ?? '',
    );
    _prixGrosCtrl = TextEditingController(
      text: a?.prixGros.toStringAsFixed(3) ?? '',
    );
    _prixDetailBarreCtrl = TextEditingController(
      text: a?.prixDetailBarre?.toStringAsFixed(3) ?? '',
    );
    _prixGrosBarreCtrl = TextEditingController(
      text: a?.prixGrosBarre?.toStringAsFixed(3) ?? '',
    );
    _familleChoisie = a?.categorie ?? widget.familleInitiale;
    _imageBytes = a?.imageBytes;
    _statut = a?.statut ?? StatutArticle.normal;
    _disponible = a?.disponible ?? true;
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _codeArticleCtrl.dispose();
    _codeBarreCtrl.dispose();
    _tailleCtrl.dispose();
    _colisageCtrl.dispose();
    _prixDetailCtrl.dispose();
    _prixGrosCtrl.dispose();
    _prixDetailBarreCtrl.dispose();
    _prixGrosBarreCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final resultat = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final octets = resultat?.files.single.bytes;
    if (octets != null) {
      setState(() => _imageBytes = octets);
    }
  }

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;

    final famille = _familleChoisie;
    if (famille == null || famille.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choisissez une famille')));
      return;
    }

    final article = Article(
      id:
          widget.articleExistant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      designation: _designationCtrl.text.trim(),
      categorie: famille,
      prixDetail: double.parse(_prixDetailCtrl.text.replaceAll(',', '.')),
      prixGros: double.parse(_prixGrosCtrl.text.replaceAll(',', '.')),
      codeArticle: _videVersNull(_codeArticleCtrl.text),
      codeBarre: _videVersNull(_codeBarreCtrl.text),
      taille: _videVersNull(_tailleCtrl.text),
      colisage: int.tryParse(_colisageCtrl.text.trim()),
      imageBytes: _imageBytes,
      statut: _statut,
      prixDetailBarre: _statut == StatutArticle.promo
          ? double.tryParse(_prixDetailBarreCtrl.text.replaceAll(',', '.'))
          : null,
      prixGrosBarre: _statut == StatutArticle.promo
          ? double.tryParse(_prixGrosBarreCtrl.text.replaceAll(',', '.'))
          : null,
      disponible: _disponible,
    );

    Navigator.of(context).pop(article);
  }

  String? _videVersNull(String s) => s.trim().isEmpty ? null : s.trim();

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
                      _modification ? 'Modifier l\'article' : 'Nouvel article',
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
                          Center(child: _buildImagePicker(accent)),
                          const SizedBox(height: 24),
                          _buildStatutSelector(),
                          const SizedBox(height: 16),
                          _buildDisponibiliteSwitch(accent),
                          const SizedBox(height: 24),
                          _buildFamilleSelector(accent),
                          const SizedBox(height: 16),
                          _champTexte(
                            controller: _designationCtrl,
                            label: 'Désignation',
                            requis: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _champTexte(
                                  controller: _codeArticleCtrl,
                                  label: 'Code article',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _champTexte(
                                  controller: _codeBarreCtrl,
                                  label: 'Code à barre',
                                  clavierNumerique: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _champTexte(
                                  controller: _tailleCtrl,
                                  label: 'Taille',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _champTexte(
                                  controller: _colisageCtrl,
                                  label: 'Colisage',
                                  clavierNumerique: true,
                                ),
                              ),
                            ],
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
                                  controller: _prixDetailCtrl,
                                  label: 'Prix détail (DT)',
                                  requis: true,
                                  clavierNumerique: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _champTexte(
                                  controller: _prixGrosCtrl,
                                  label: 'Prix gros (DT)',
                                  requis: true,
                                  clavierNumerique: true,
                                ),
                              ),
                            ],
                          ),
                          if (_statut == StatutArticle.promo) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Ancien prix (affiché barré, facultatif)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _champTexte(
                                    controller: _prixDetailBarreCtrl,
                                    label: 'Ancien prix détail (DT)',
                                    clavierNumerique: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _champTexte(
                                    controller: _prixGrosBarreCtrl,
                                    label: 'Ancien prix gros (DT)',
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
                          : 'Ajouter l\'article',
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

  Widget _buildImagePicker(List<Color> accent) {
    return GestureDetector(
      onTap: _choisirImage,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.last.withValues(alpha: 0.3),
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _choisirImage,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit, size: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34,
                    color: accent.last.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: accent.last.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatutSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut de l\'article',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final statut in StatutArticle.values) ...[
              Expanded(child: _statutChip(statut)),
              if (statut != StatutArticle.values.last)
                const SizedBox(width: 10),
            ],
          ],
        ),
        if (_statut != StatutArticle.normal) ...[
          const SizedBox(height: 8),
          Text(
            _statut == StatutArticle.promo
                ? 'Un bandeau "Promo" s\'affichera automatiquement sur la carte. Pensez à mettre à jour le prix ci-dessous.'
                : 'Un bandeau "Nouveauté" s\'affichera automatiquement sur la carte.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statutChip(StatutArticle statut) {
    final selectionne = _statut == statut;
    final degrade = statut.degradeBandeau;
    final couleur = degrade?.last ?? const Color(0xFF6B7A8D);
    return Material(
      color: selectionne ? null : const Color(0xFFF3F5F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _statut = statut),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selectionne
                ? LinearGradient(colors: degrade ?? [couleur, couleur])
                : null,
            border: Border.all(
              color: selectionne
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statut.icone,
                size: 18,
                color: selectionne ? Colors.white : couleur,
              ),
              const SizedBox(height: 4),
              Text(
                statut.libelle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selectionne ? Colors.white : const Color(0xFF1B3B5F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisponibiliteSwitch(List<Color> accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _disponible,
        onChanged: (v) => setState(() => _disponible = v),
        activeThumbColor: accent.last,
        title: Text(
          _disponible ? 'En stock' : 'Rupture de stock',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _disponible
              ? 'Visible comme disponible dans le catalogue'
              : 'Affiché comme en rupture (grisé) dans le catalogue',
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilleSelector(List<Color> accent) {
    return DropdownButtonFormField<String>(
      initialValue: widget.famillesExistantes.contains(_familleChoisie)
          ? _familleChoisie
          : null,
      decoration: _decorationChamp('Famille'),
      items: widget.famillesExistantes
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (valeur) => setState(() => _familleChoisie = valeur),
      validator: (v) => v == null ? 'Choisissez une famille' : null,
    );
  }

  InputDecoration _decorationChamp(String label, {Widget? suffixe}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixe,
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
    Widget? suffixe,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: clavierNumerique
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _decorationChamp(label, suffixe: suffixe),
      validator: requis
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}
