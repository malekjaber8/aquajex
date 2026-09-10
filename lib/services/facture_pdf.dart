import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/client.dart';
import '../models/commande.dart';
import '../models/tarif.dart';

String _formatMontantPdf(double montant) {
  final parts = montant.toStringAsFixed(3).split('.');
  final chiffres = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(chiffres[i]);
  }
  return '${buffer.toString()},${parts[1]} DT';
}

String _formatDatePdf(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Construit le PDF de la facture pour une commande, avec le logo de la
/// marque et les informations complètes du client.
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

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête : logo + marque à gauche, "FACTURE" + date/N° à droite.
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(height: 54, width: 54, child: pw.Image(logo)),
                pw.SizedBox(width: 14),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tarif.nom,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: encre,
                      ),
                    ),
                    pw.Text(
                      'Catalogue professionnel',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FACTURE PROFORMA',
                      style: pw.TextStyle(
                        fontSize: 16,
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
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 14),

            // Informations client.
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
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
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        if (client?.telephone != null)
                          pw.Text(
                            'Tél : ${client!.telephone}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        if (client?.adresse != null)
                          pw.Text(
                            client!.adresse!,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INFORMATIONS',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (client?.matriculeFiscal != null)
                          pw.Text(
                            'Matricule fiscal : ${client!.matriculeFiscal}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        if (client?.cin != null)
                          pw.Text(
                            'CIN : ${client!.cin}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        pw.Text(
                          'Mode de prix : ${commande.modePrix.libelle}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tableau des articles.
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3.1),
                1: pw.FlexColumnWidth(0.8),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: accent),
                  children: [
                    _celluleEntete('Désignation'),
                    _celluleEntete('Qté', droite: false),
                    _celluleEntete('Prix U.'),
                    _celluleEntete('Total'),
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: pw.Text(
                          ligne.designation,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: pw.Text(
                          '${ligne.quantite}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: pw.Text(
                          _formatMontantPdf(ligne.prixUnitaire),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: pw.Text(
                          _formatMontantPdf(ligne.total),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Total.
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'TOTAL   ',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        _formatMontantPdf(commande.total),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (commande.note != null && commande.note!.isNotEmpty) ...[
              pw.SizedBox(height: 16),
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
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Merci de votre confiance.',
                style: const pw.TextStyle(
                  fontSize: 9,
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

pw.Widget _celluleEntete(String texte, {bool droite = true}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: pw.Text(
      texte,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );
}
