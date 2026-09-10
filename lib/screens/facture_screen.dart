import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/tarif.dart';
import '../services/facture_pdf.dart';
import '../widgets/decorative_background.dart';

class FactureScreen extends StatefulWidget {
  final Commande commande;
  final Client? client;
  final Tarif tarif;
  final VoidCallback? onModifier;

  const FactureScreen({
    super.key,
    required this.commande,
    required this.client,
    required this.tarif,
    this.onModifier,
  });

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  bool _enCours = false;
  bool _impressionEnCours = false;

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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _imprimer() async {
    setState(() => _impressionEnCours = true);
    try {
      await Printing.layoutPdf(
        name: 'facture_${widget.commande.id}.pdf',
        onLayout: (_) => genererFacturePdf(
          commande: widget.commande,
          client: widget.client,
          tarif: widget.tarif,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Échec de l\'impression : $e')));
    } finally {
      if (mounted) setState(() => _impressionEnCours = false);
    }
  }

  Future<void> _partager() async {
    setState(() => _enCours = true);
    try {
      final octets = await genererFacturePdf(
        commande: widget.commande,
        client: widget.client,
        tarif: widget.tarif,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [
          XFile.fromData(
            octets,
            name: 'facture_${widget.commande.id}.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text:
            'Facture ${widget.commande.clientNom} — '
            '${_formatMontant(widget.commande.total)} DT',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Échec du partage : $e')));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tarif.accentGradient;
    final commande = widget.commande;
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
                        'Facture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3B5F),
                        ),
                      ),
                    ),
                    if (widget.onModifier != null)
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onModifier!();
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF1B3B5F),
                        ),
                        tooltip: 'Modifier',
                      ),
                    IconButton(
                      onPressed: _impressionEnCours ? null : _imprimer,
                      icon: _impressionEnCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.print_outlined,
                              color: Color(0xFF1B3B5F),
                            ),
                      tooltip: 'Imprimer',
                    ),
                    IconButton(
                      onPressed: _enCours ? null : _partager,
                      icon: _enCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.ios_share,
                              color: Color(0xFF1B3B5F),
                            ),
                      tooltip: 'Enregistrer / Partager (WhatsApp…)',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    widget.tarif.logoAsset,
                                    height: 54,
                                    width: 54,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tarif.nom,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1B3B5F),
                                      ),
                                    ),
                                    Text(
                                      'Catalogue professionnel',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(colors: accent)
                                              .createShader(bounds),
                                      child: const Text(
                                        'FACTURE PROFORMA',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'N° ${commande.id}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(commande.date),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.black.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _labelPetit('CLIENT'),
                                        const SizedBox(height: 4),
                                        Text(
                                          commande.clientNom,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1B3B5F),
                                          ),
                                        ),
                                        if (client?.nomSociete != null)
                                          _texteInfo(client!.nomSociete!),
                                        if (client?.telephone != null)
                                          _texteInfo(
                                            'Tél : ${client!.telephone}',
                                          ),
                                        if (client?.adresse != null)
                                          _texteInfo(client!.adresse!),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _labelPetit('INFORMATIONS'),
                                        const SizedBox(height: 4),
                                        if (client?.matriculeFiscal != null)
                                          _texteInfo(
                                            'Matricule fiscal : ${client!.matriculeFiscal}',
                                          ),
                                        if (client?.cin != null)
                                          _texteInfo('CIN : ${client!.cin}'),
                                        _texteInfo(
                                          'Mode de prix : ${commande.modePrix.libelle}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: accent),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      'Désignation',
                                      style: _styleEntete,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Qté', style: _styleEntete),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Prix U.',
                                      textAlign: TextAlign.right,
                                      style: _styleEntete,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Total',
                                      textAlign: TextAlign.right,
                                      style: _styleEntete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final ligne in commande.lignes)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        ligne.designation,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1B3B5F),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${ligne.quantite}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1B3B5F),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${_formatMontant(ligne.prixUnitaire)} DT',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1B3B5F),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${_formatMontant(ligne.total)} DT',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: accent.last,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'TOTAL   ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_formatMontant(commande.total)} DT',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: accent.last,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (commande.note != null &&
                                commande.note!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelPetit('NOTE'),
                                    const SizedBox(height: 6),
                                    Text(
                                      commande.note!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Divider(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Merci de votre confiance.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black.withValues(alpha: 0.4),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelPetit(String texte) => Text(
    texte,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Colors.black.withValues(alpha: 0.4),
    ),
  );

  Widget _texteInfo(String texte) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      texte,
      style: TextStyle(
        fontSize: 12,
        color: Colors.black.withValues(alpha: 0.65),
      ),
    ),
  );
}

const _styleEntete = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);
