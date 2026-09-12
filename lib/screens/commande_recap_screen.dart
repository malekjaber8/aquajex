import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';
import '../widgets/decorative_background.dart';
import 'facture_screen.dart';

/// Étape intermédiaire entre le panier et la facture proforma : un
/// récapitulatif de la commande (client, articles, total) avec une zone de
/// note facultative, à confirmer explicitement avant que la facture ne
/// s'affiche.
class CommandeRecapScreen extends StatefulWidget {
  final Client client;
  final List<LigneCommande> lignes;
  final Tarif tarif;
  final ModePrix modePrix;
  final Future<Commande> Function(String? note, double remisePourcent)
  onConfirmer;
  final ValueChanged<Commande> onModifier;

  const CommandeRecapScreen({
    super.key,
    required this.client,
    required this.lignes,
    required this.tarif,
    required this.modePrix,
    required this.onConfirmer,
    required this.onModifier,
  });

  @override
  State<CommandeRecapScreen> createState() => _CommandeRecapScreenState();
}

class _CommandeRecapScreenState extends State<CommandeRecapScreen> {
  final _noteCtrl = TextEditingController();
  final _remiseCtrl = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _remiseCtrl.dispose();
    super.dispose();
  }

  double get _totalHt => widget.lignes.fold(0, (s, l) => s + l.total);

  double get _remisePourcent =>
      double.tryParse(_remiseCtrl.text.trim().replaceAll(',', '.')) ?? 0;

  double get _remiseMontant => _totalHt * (_remisePourcent / 100);
  double get _totalHtNet => _totalHt - _remiseMontant;
  double get _tva => _totalHtNet * tauxTvaFacture;
  double get _totalTtc => _totalHtNet + _tva;

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(3).split('.');
    final chiffres = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(chiffres[i]);
    }
    return '${buffer.toString()},${parts[1]}';
  }

  Widget _ligneTotal(String label, double valeur) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Text(
          '${valeur < 0 ? '- ' : ''}${_formatMontant(valeur.abs())} DT',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmer() async {
    setState(() => _enCours = true);
    final note = _noteCtrl.text.trim();
    try {
      final commande = await widget.onConfirmer(
        note.isEmpty ? null : note,
        _remisePourcent,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FactureScreen(
            commande: commande,
            client: widget.client,
            tarif: widget.tarif,
            onModifier: () => widget.onModifier(commande),
          ),
        ),
      );
    } catch (e) {
      // Sans ce filet, un échec d'enregistrement (ex : Firestore refuse
      // l'écriture) ne montrait rien à l'écran — le panier n'était pas vidé
      // mais rien n'expliquait pourquoi la commande n'apparaissait jamais.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'enregistrement de la commande : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tarif.accentGradient;
    final client = widget.client;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1B3B5F),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Récapitulatif de la commande',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3B5F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: accent.last.withValues(
                                    alpha: 0.15,
                                  ),
                                  foregroundColor: accent.last,
                                  child: Text(client.initiales),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.nomAffichage,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B3B5F),
                                        ),
                                      ),
                                      if (client.estSociete &&
                                          client.responsable != null)
                                        Text(
                                          client.responsable!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                for (final ligne in widget.lignes)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ligne.designation,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1B3B5F),
                                                ),
                                              ),
                                              Text(
                                                '${ligne.quantite} × ${_formatMontant(ligne.prixUnitaire)} DT',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.45),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${_formatMontant(ligne.total)} DT',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: accent.last,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    12,
                                  ),
                                  child: Column(
                                    children: [
                                      _ligneTotal('Total HT', _totalHt),
                                      if (_remisePourcent > 0)
                                        _ligneTotal(
                                          'Remise (${_formatMontant(_remisePourcent)}%)',
                                          -_remiseMontant,
                                        ),
                                      _ligneTotal(
                                        'TVA (${(tauxTvaFacture * 100).toStringAsFixed(0)}%)',
                                        _tva,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total TTC',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1B3B5F),
                                            ),
                                          ),
                                          Text(
                                            '${_formatMontant(_totalTtc)} DT',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: accent.last,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.percent,
                                      size: 18,
                                      color: accent.last,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remise (facultative)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1B3B5F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _remiseCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Pourcentage de remise, ex. 5',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F5F8),
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 18,
                                      color: accent.last,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Note (facultative)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1B3B5F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _noteCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Écrire une remarque à inclure sur la facture proforma…',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F5F8),
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: accent),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _enCours ? null : _confirmer,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: _enCours
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Confirmer la commande',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
