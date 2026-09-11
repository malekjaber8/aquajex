import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import '../models/commande.dart';
import '../models/tarif.dart';
import '../services/facture_pdf.dart';
import '../services/montant_lettres.dart';
import '../widgets/decorative_background.dart';

// Coordonnées légales de la société, identiques sur toutes les factures
// (Aquajex et Les Cinq Frères sont deux gammes de la même société).
const _raisonSociale = 'STE AQUAJEX 5F';
const _activite = 'VENTE PRODUITS DIVERS';
const _adresseSociete = 'ROUTE DE TENIOUR KM 12 - 3041 SFAX - TUNISIE';
const _tvaSociete = 'TVA : 1850797 MAM 000';
const _rcSociete = 'RC.: C 081538 2024';
const _telSociete = 'Tél. : 29 94 04 91';

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
            'Facture proforma ${widget.commande.clientNom} — '
            '${_formatMontant(widget.commande.totalTtc)} DT',
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
    final remisePourcent = commande.remisePourcent;

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
                        'Facture proforma',
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final etroit = constraints.maxWidth < 480;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
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
                                // En-tête : logo + coordonnées légales — côte à
                                // côte sur écran large, empilés (logo au-dessus,
                                // texte aligné à gauche) sur mobile pour que rien
                                // ne se compresse ni ne se coupe.
                                if (etroit)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 56,
                                        width: 96,
                                        child: Image.asset(
                                          widget.tarif.logoAsset,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        _raisonSociale,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B3B5F),
                                        ),
                                      ),
                                      Text(
                                        _activite,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _texteInfoGauche(_adresseSociete),
                                      _texteInfoGauche(_tvaSociete),
                                      _texteInfoGauche(_rcSociete),
                                      _texteInfoGauche(_telSociete),
                                    ],
                                  )
                                else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 64,
                                        width: 110,
                                        child: Image.asset(
                                          widget.tarif.logoAsset,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            _raisonSociale,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1B3B5F),
                                            ),
                                          ),
                                          Text(
                                            _activite,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          _texteInfoDroite(_adresseSociete),
                                          _texteInfoDroite(
                                            '$_tvaSociete   $_rcSociete',
                                          ),
                                          _texteInfoDroite(_telSociete),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 18),
                                Divider(
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                                const SizedBox(height: 14),

                                // Facture (N°, date) + client, côte à côte.
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final etroit = constraints.maxWidth < 480;
                                    final blocFacture = Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                LinearGradient(colors: accent)
                                                    .createShader(bounds),
                                            child: const Text(
                                              'FACTURE PROFORMA',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _texteInfo('N° ${commande.id}'),
                                          _texteInfo(
                                            _formatDate(commande.date),
                                          ),
                                          const SizedBox(height: 2),
                                          _texteInfo(
                                            'Mode de prix : ${commande.modePrix.libelle}',
                                          ),
                                        ],
                                      ),
                                    );
                                    final blocClient = Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                          if (client?.estSociete == true &&
                                              client?.responsable != null)
                                            _texteInfo(
                                              'Responsable : ${client!.responsable}',
                                            ),
                                          if (client?.telephone != null)
                                            _texteInfo(
                                              'Tél : ${client!.telephone}',
                                            ),
                                          if (client?.adresse != null)
                                            _texteInfo(client!.adresse!),
                                          if (client?.matriculeFiscal != null)
                                            _texteInfo(
                                              'Matricule fiscal : ${client!.matriculeFiscal}',
                                            ),
                                          if (client?.cin != null)
                                            _texteInfo('CIN : ${client!.cin}'),
                                        ],
                                      ),
                                    );
                                    if (etroit) {
                                      return Column(
                                        children: [
                                          blocFacture,
                                          const SizedBox(height: 12),
                                          blocClient,
                                        ],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: blocFacture),
                                        const SizedBox(width: 12),
                                        Expanded(child: blocClient),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Tableau des articles. Sur mobile, un tableau
                                // large défilant horizontalement laisserait la
                                // plupart des colonnes hors écran — on affiche
                                // plutôt une carte empilée par article, tout
                                // reste visible sans glisser latéralement.
                                if (etroit)
                                  Column(
                                    children: [
                                      for (final ligne in commande.lignes)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F8FA),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ligne.designation,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1B3B5F),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Réf : ${ligne.codeArticle ?? '-'}   ·   '
                                                'CB : ${ligne.codeBarre ?? '-'}'
                                                '${ligne.colisage != null ? '   ·   Colisage : ${ligne.colisage}' : ''}',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${ligne.quantite} × ${_formatMontant(ligne.prixUnitaire)} DT HT'
                                                    '${remisePourcent > 0 ? '  ·  -${remisePourcent.toStringAsFixed(0)}%' : ''}',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'TVA ${(tauxTvaFacture * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  '${_formatMontant(ligne.prixUnitaire * (1 - remisePourcent / 100) * (1 + tauxTvaFacture))} DT TTC',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: accent.last,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: 760,
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 9,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: accent,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                _Cellule(
                                                  flex: 11,
                                                  texte: 'Référence',
                                                  style: _styleEntete,
                                                ),
                                                _Cellule(
                                                  flex: 14,
                                                  texte: 'Code Barre',
                                                  style: _styleEntete,
                                                ),
                                                _Cellule(
                                                  flex: 24,
                                                  texte: 'Désignation',
                                                  style: _styleEntete,
                                                ),
                                                _Cellule(
                                                  flex: 6,
                                                  texte: 'Col.',
                                                  style: _styleEntete,
                                                ),
                                                _Cellule(
                                                  flex: 6,
                                                  texte: 'Qté',
                                                  style: _styleEntete,
                                                ),
                                                _Cellule(
                                                  flex: 9,
                                                  texte: 'P.U. HT',
                                                  style: _styleEntete,
                                                  droite: true,
                                                ),
                                                _Cellule(
                                                  flex: 8,
                                                  texte: 'Remise',
                                                  style: _styleEntete,
                                                  droite: true,
                                                ),
                                                _Cellule(
                                                  flex: 9,
                                                  texte: 'Mnt H.T',
                                                  style: _styleEntete,
                                                  droite: true,
                                                ),
                                                _Cellule(
                                                  flex: 6,
                                                  texte: 'TVA',
                                                  style: _styleEntete,
                                                  droite: true,
                                                ),
                                                _Cellule(
                                                  flex: 9,
                                                  texte: 'P.U. TTC',
                                                  style: _styleEntete,
                                                  droite: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                          for (final ligne in commande.lignes)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 9,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.06,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  _Cellule(
                                                    flex: 11,
                                                    texte:
                                                        ligne.codeArticle ??
                                                        '-',
                                                  ),
                                                  _Cellule(
                                                    flex: 14,
                                                    texte:
                                                        ligne.codeBarre ?? '-',
                                                  ),
                                                  _Cellule(
                                                    flex: 24,
                                                    texte: ligne.designation,
                                                  ),
                                                  _Cellule(
                                                    flex: 6,
                                                    texte:
                                                        ligne.colisage != null
                                                        ? '${ligne.colisage}'
                                                        : '-',
                                                  ),
                                                  _Cellule(
                                                    flex: 6,
                                                    texte: '${ligne.quantite}',
                                                  ),
                                                  _Cellule(
                                                    flex: 9,
                                                    texte: _formatMontant(
                                                      ligne.prixUnitaire,
                                                    ),
                                                    droite: true,
                                                  ),
                                                  _Cellule(
                                                    flex: 8,
                                                    texte:
                                                        '${remisePourcent.toStringAsFixed(0)}%',
                                                    droite: true,
                                                  ),
                                                  _Cellule(
                                                    flex: 9,
                                                    texte: _formatMontant(
                                                      ligne.total *
                                                          (1 -
                                                              remisePourcent /
                                                                  100),
                                                    ),
                                                    droite: true,
                                                    gras: true,
                                                    couleur: accent.last,
                                                  ),
                                                  _Cellule(
                                                    flex: 6,
                                                    texte:
                                                        '${(tauxTvaFacture * 100).toStringAsFixed(0)}%',
                                                    droite: true,
                                                  ),
                                                  _Cellule(
                                                    flex: 9,
                                                    texte: _formatMontant(
                                                      ligne.prixUnitaire *
                                                          (1 -
                                                              remisePourcent /
                                                                  100) *
                                                          (1 + tauxTvaFacture),
                                                    ),
                                                    droite: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // Totaux.
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 260,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        _ligneTotal(
                                          'TOTAL HT',
                                          commande.totalHt,
                                        ),
                                        if (remisePourcent > 0)
                                          _ligneTotal(
                                            'REMISE (${remisePourcent.toStringAsFixed(0)}%)',
                                            -commande.remiseMontant,
                                          ),
                                        _ligneTotal(
                                          'TOTAL HT (NET)',
                                          commande.totalHtNet,
                                        ),
                                        const SizedBox(height: 4),
                                        _ligneTotal(
                                          'T.V.A.',
                                          commande.montantTva,
                                        ),
                                        const SizedBox(height: 6),
                                        Divider(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'TOTAL T.T.C.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1B3B5F),
                                              ),
                                            ),
                                            Text(
                                              '${_formatMontant(commande.totalTtc)} DT',
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800,
                                                color: accent.last,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Montant en toutes lettres.
                                Text(
                                  'ARRETEE LA PRESENTE A LA SOMME DE :',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  montantEnLettres(commande.totalTtc),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.black.withValues(alpha: 0.75),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

                                // Cachet & signature.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'CACHET & SIGNATURE',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 70,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'CACHET & SIGNATURE CLIENT',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Document proforma — sans valeur fiscale — Merci de votre confiance.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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

  Widget _texteInfoDroite(String texte) => Text(
    texte,
    textAlign: TextAlign.right,
    style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.55)),
  );

  Widget _texteInfoGauche(String texte) => Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Text(
      texte,
      style: TextStyle(
        fontSize: 10.5,
        color: Colors.black.withValues(alpha: 0.55),
      ),
    ),
  );

  Widget _ligneTotal(String label, double valeur) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Text(
          '${valeur < 0 ? '- ' : ''}${_formatMontant(valeur.abs())} DT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}

class _Cellule extends StatelessWidget {
  final int flex;
  final String texte;
  final TextStyle? style;
  final bool droite;
  final bool gras;
  final Color? couleur;

  const _Cellule({
    required this.flex,
    required this.texte,
    this.style,
    this.droite = false,
    this.gras = false,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        texte,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: droite ? TextAlign.right : TextAlign.left,
        style:
            style ??
            TextStyle(
              fontSize: 11.5,
              fontWeight: gras ? FontWeight.w700 : FontWeight.normal,
              color: couleur ?? const Color(0xFF1B3B5F),
            ),
      ),
    );
  }
}

const _styleEntete = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);
