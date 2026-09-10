import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/client.dart';
import '../models/commande.dart';
import '../models/tarif.dart';
import 'montant_lettres.dart';

// Coordonnées légales de la société, identiques sur toutes les factures
// (Aquajex et Les Cinq Frères sont deux gammes de la même société).
const _raisonSociale = 'STE AQUAJEX 5F';
const _activite = 'VENTE PRODUITS DIVERS';
const _adresseSociete = 'ROUTE DE TENIOUR KM 12 - 3041 SFAX - TUNISIE';
const _tvaSociete = 'TVA : 1850797 MAM 000';
const _rcSociete = 'RC.: C 081538 2024';
const _telSociete = 'Tél. : 29 94 04 91';

String _formatMontantPdf(double montant) {
  final parts = montant.toStringAsFixed(3).split('.');
  final chiffres = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(chiffres[i]);
  }
  return '${buffer.toString()},${parts[1]}';
}

String _formatDatePdf(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Construit le PDF de la facture proforma pour une commande, dans le style
/// des factures officielles de la société : logo + coordonnées légales,
/// tableau détaillé (référence, code barre, colisage, HT/remise/TVA/TTC),
/// totaux et montant en toutes lettres.
Future<Uint8List> genererFacturePdf({
  required Commande commande,
  required Client? client,
  required Tarif tarif,
}) async {
  final document = pw.Document();

  final logoOctets = await rootBundle.load(tarif.logoAsset);
  final logo = pw.MemoryImage(logoOctets.buffer.asUint8List());

  final accent = PdfColor.fromInt(tarif.accentColor.toARGB32());
  const encre = PdfColor.fromInt(0xFF1B3B5F);
  final remisePourcent = commande.remisePourcent;

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête : logo à gauche, coordonnées légales à droite.
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 60,
                  width: 100,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _raisonSociale,
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: encre,
                      ),
                    ),
                    pw.Text(
                      _activite,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      _adresseSociete,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      '$_tvaSociete   $_rcSociete',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      _telSociete,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            // Facture (N°, date) + informations client, côte à côte.
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FACTURE PROFORMA',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'N° ${commande.id}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          _formatDatePdf(commande.date),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mode de prix : ${commande.modePrix.libelle}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLIENT',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          commande.clientNom,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: encre,
                          ),
                        ),
                        if (client?.nomSociete != null)
                          pw.Text(
                            client!.nomSociete!,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (client?.telephone != null)
                          pw.Text(
                            'Tél : ${client!.telephone}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (client?.adresse != null)
                          pw.Text(
                            client!.adresse!,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (client?.matriculeFiscal != null)
                          pw.Text(
                            'Matricule fiscal : ${client!.matriculeFiscal}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (client?.cin != null)
                          pw.Text(
                            'CIN : ${client!.cin}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Tableau des articles.
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1.1),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(2.5),
                3: pw.FlexColumnWidth(0.6),
                4: pw.FlexColumnWidth(0.6),
                5: pw.FlexColumnWidth(0.9),
                6: pw.FlexColumnWidth(0.8),
                7: pw.FlexColumnWidth(0.9),
                8: pw.FlexColumnWidth(0.6),
                9: pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: accent),
                  children: [
                    _celluleEntete('Référence'),
                    _celluleEntete('Code Barre'),
                    _celluleEntete('Désignation'),
                    _celluleEntete('Col.'),
                    _celluleEntete('Qté'),
                    _celluleEntete('P.U. HT'),
                    _celluleEntete('Remise'),
                    _celluleEntete('Mnt H.T'),
                    _celluleEntete('TVA'),
                    _celluleEntete('P.U. TTC'),
                  ],
                ),
                for (final ligne in commande.lignes)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    children: [
                      _celluleCorps(ligne.codeArticle ?? '-'),
                      _celluleCorps(ligne.codeBarre ?? '-'),
                      _celluleCorps(ligne.designation),
                      _celluleCorps(
                        ligne.colisage != null ? '${ligne.colisage}' : '-',
                      ),
                      _celluleCorps('${ligne.quantite}'),
                      _celluleCorps(_formatMontantPdf(ligne.prixUnitaire)),
                      _celluleCorps('${remisePourcent.toStringAsFixed(0)}%'),
                      _celluleCorps(
                        _formatMontantPdf(
                          ligne.total * (1 - remisePourcent / 100),
                        ),
                        gras: true,
                      ),
                      _celluleCorps(
                        '${(tauxTvaFacture * 100).toStringAsFixed(0)}%',
                      ),
                      _celluleCorps(
                        _formatMontantPdf(
                          ligne.prixUnitaire *
                              (1 - remisePourcent / 100) *
                              (1 + tauxTvaFacture),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Totaux.
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _ligneTotalPdf('TOTAL HT', commande.totalHt),
                      if (remisePourcent > 0)
                        _ligneTotalPdf(
                          'REMISE (${remisePourcent.toStringAsFixed(0)}%)',
                          -commande.remiseMontant,
                        ),
                      _ligneTotalPdf('TOTAL HT (NET)', commande.totalHtNet),
                      pw.SizedBox(height: 4),
                      _ligneTotalPdf('T.V.A.', commande.montantTva),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL T.T.C.',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: encre,
                            ),
                          ),
                          pw.Text(
                            '${_formatMontantPdf(commande.totalTtc)} DT',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Montant en toutes lettres.
            pw.Text(
              'ARRETEE LA PRESENTE A LA SOMME DE :',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              montantEnLettres(commande.totalTtc),
              style: const pw.TextStyle(fontSize: 9),
            ),

            if (commande.note != null && commande.note!.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NOTE',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      commande.note!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],

            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    height: 70,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'CACHET & SIGNATURE',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    height: 70,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'CACHET & SIGNATURE CLIENT',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Document proforma — sans valeur fiscale — Merci de votre confiance.',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return document.save();
}

pw.Widget _celluleEntete(String texte) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
    child: pw.Text(
      texte,
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );
}

pw.Widget _celluleCorps(String texte, {bool gras = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: pw.Text(
      texte,
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _ligneTotalPdf(String label, double valeur) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
      ),
      pw.Text(
        '${valeur < 0 ? '- ' : ''}${_formatMontantPdf(valeur.abs())}',
        style: const pw.TextStyle(fontSize: 8.5),
      ),
    ],
  ),
);
