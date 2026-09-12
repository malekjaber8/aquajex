import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/article.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';

const _raisonSociale = 'STE AQUAJEX 5F';
const _adresseSociete = 'ROUTE DE TENIOUR KM 12 - 3041 SFAX - TUNISIE';
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

/// Construit le PDF du catalogue complet (toutes les familles, tous leurs
/// articles), avec photo, désignation, codes et le prix actuellement
/// affiché à l'écran (détail ou gros selon [modePrix]) — un document de
/// référence à imprimer ou partager, pas une facture.
Future<Uint8List> genererCataloguePdf({
  required Tarif tarif,
  required ModePrix modePrix,
  required List<String> familles,
  required List<Article> articles,
}) async {
  final document = pw.Document();

  final logoOctets = await rootBundle.load(tarif.logoAsset);
  final logo = pw.MemoryImage(logoOctets.buffer.asUint8List());
  final accent = PdfColor.fromInt(tarif.accentColor.toARGB32());
  const encre = PdfColor.fromInt(0xFF1B3B5F);

  final famillesTriees = [...familles]..sort();

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
      header: (context) {
        if (context.pageNumber > 1) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Catalogue ${tarif.nom}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: encre,
                  ),
                ),
                pw.Text(
                  modePrix.libelle,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 56,
                  width: 96,
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
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: encre,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      _adresseSociete,
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
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CATALOGUE ${tarif.nom.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    modePrix.libelle,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
        );
      },
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ),
      build: (context) {
        final blocs = <pw.Widget>[];
        for (final famille in famillesTriees) {
          final articlesFamille =
              articles.where((a) => a.categorie == famille).toList()
                ..sort((a, b) => a.designation.compareTo(b.designation));
          if (articlesFamille.isEmpty) continue;
          blocs.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
              child: pw.Row(
                children: [
                  pw.Container(width: 4, height: 16, color: accent),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    famille.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: encre,
                    ),
                  ),
                ],
              ),
            ),
          );
          blocs.add(
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final article in articlesFamille)
                  _carteArticle(article, modePrix, accent, encre),
              ],
            ),
          );
        }
        return blocs;
      },
    ),
  );

  return document.save();
}

pw.Widget _carteArticle(
  Article article,
  ModePrix modePrix,
  PdfColor accent,
  PdfColor encre,
) {
  return pw.Container(
    width: 122,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 70,
          width: double.infinity,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: article.imageBytes != null
              ? pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(
                    pw.MemoryImage(article.imageBytes!),
                    fit: pw.BoxFit.contain,
                    height: 70,
                    width: double.infinity,
                  ),
                )
              : pw.Text(
                  article.designation.isNotEmpty
                      ? article.designation[0].toUpperCase()
                      : '?',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.grey400,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          article.designation,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: encre,
          ),
        ),
        if (article.codeArticle != null)
          pw.Text(
            article.codeArticle!,
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
        if (article.colisage != null)
          pw.Text(
            'Colisage : ${article.colisage}',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
        pw.SizedBox(height: 3),
        pw.Text(
          '${_formatMontantPdf(article.prixPour(modePrix))} DT',
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: accent,
          ),
        ),
      ],
    ),
  );
}
