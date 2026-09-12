import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/article.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/mode_prix.dart';
import '../models/note.dart';
import '../models/tarif.dart';
import '../services/auth_service.dart';
import '../services/catalogue_pdf.dart';
import '../services/catalogue_repository.dart';
import '../services/gestion_repository.dart';
import '../widgets/changer_mot_de_passe_sheet.dart';
import '../widgets/commande_edit_sheet.dart';
import '../widgets/decorative_background.dart';
import '../widgets/gestion_stock_view.dart';
import '../widgets/panier_sheet.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/statut_articles_view.dart';
import 'article_form_screen.dart';
import 'client_form_screen.dart';
import 'commande_recap_screen.dart';
import 'note_form_screen.dart';
import 'sections/catalogue_section.dart';
import 'sections/clients_section.dart';
import 'sections/commandes_section.dart';
import 'sections/notes_section.dart';

class CatalogueScreen extends StatefulWidget {
  final Tarif tarif;
  final ModePrix modePrix;
  final bool isAdmin;

  const CatalogueScreen({
    super.key,
    required this.tarif,
    required this.modePrix,
    required this.isAdmin,
  });

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late final CatalogueRepository _repo = CatalogueRepository(widget.tarif);
  late final GestionRepository _gestionRepo = GestionRepository(widget.tarif);

  int _selectedIndex = 0;
  String? _familleSelectionnee;
  String _rechercheArticle = '';
  String _rechercheClient = '';
  String _rechercheCommande = '';
  StatutArticle? _filtreStatut;
  StatutCommande? _filtreStatutCommande;
  bool _chargementGestion = true;
  bool _chargementFamilles = true;
  bool _chargementArticles = true;
  String? _erreurGestion;
  bool get _chargement =>
      _chargementGestion || _chargementFamilles || _chargementArticles;
  List<Article> _articles = [];
  List<String> _familles = [];
  List<Client> _clients = [];
  List<Commande> _commandes = [];
  List<Note> _notes = [];
  final List<LigneCommande> _panier = [];

  List<ArticleAvecTarif> _articlesPromo = [];
  List<ArticleAvecTarif> _articlesNouveaute = [];
  List<ArticleAvecTarif> _articlesTous = [];

  StreamSubscription<List<String>>? _famillesSub;
  StreamSubscription<List<Article>>? _articlesSub;
  StreamSubscription<List<ArticleAvecTarif>>? _promoSub;
  StreamSubscription<List<ArticleAvecTarif>>? _nouveauteSub;
  StreamSubscription<List<ArticleAvecTarif>>? _tousSub;

  static const _items = [
    SidebarItem(icon: Icons.grid_view_rounded, label: 'Catalogue'),
    SidebarItem(icon: Icons.local_offer_outlined, label: 'Promotion'),
    SidebarItem(icon: Icons.auto_awesome_outlined, label: 'Nouveauté'),
    SidebarItem(icon: Icons.inventory_outlined, label: 'Stock'),
    SidebarItem(icon: Icons.people_outline, label: 'Clients'),
    SidebarItem(icon: Icons.request_quote_outlined, label: 'Commandes'),
    SidebarItem(icon: Icons.sticky_note_2_outlined, label: 'Notes'),
  ];

  static const _indexCatalogue = 0;
  static const _indexPromotion = 1;
  static const _indexNouveaute = 2;
  static const _indexStock = 3;
  static const _indexClients = 4;
  static const _indexCommandes = 5;
  static const _indexNotes = 6;

  @override
  void initState() {
    super.initState();
    _chargerGestion();
    // Le catalogue (familles/articles) est partagé en direct via Firestore :
    // toute modification faite par l'admin (PC) apparaît ici automatiquement,
    // sans rechargement manuel.
    _famillesSub = _repo.streamFamilles().listen(
      (familles) {
        if (!mounted) return;
        setState(() {
          _familles = familles;
          _chargementFamilles = false;
        });
      },
      onError: (_) {
        // Se produit normalement à la déconnexion (les règles Firestore
        // coupent l'accès à un utilisateur qui n'est plus authentifié) :
        // l'écran est de toute façon en train de disparaître, rien à faire.
      },
    );
    _articlesSub = _repo.streamArticles().listen((articles) {
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _chargementArticles = false;
      });
    }, onError: (_) {});
    // Mélange les deux catalogues (Aquajex + Les Cinq Frères) pour les
    // rubriques Promotion/Nouveauté/Stock, identiques à celles de la page
    // d'accueil.
    _promoSub = CatalogueRepository.streamArticlesParStatut(StatutArticle.promo)
        .listen((articles) {
          if (!mounted) return;
          setState(() => _articlesPromo = articles);
        }, onError: (_) {});
    _nouveauteSub =
        CatalogueRepository.streamArticlesParStatut(StatutArticle.nouveaute)
            .listen((articles) {
              if (!mounted) return;
              setState(() => _articlesNouveaute = articles);
            }, onError: (_) {});
    _tousSub = CatalogueRepository.streamTousArticles().listen((articles) {
      if (!mounted) return;
      setState(() => _articlesTous = articles);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _famillesSub?.cancel();
    _articlesSub?.cancel();
    _promoSub?.cancel();
    _nouveauteSub?.cancel();
    _tousSub?.cancel();
    super.dispose();
  }

  void _ouvrirCatalogueTarif(Tarif tarif) {
    if (tarif == widget.tarif) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CatalogueScreen(
          tarif: tarif,
          modePrix: widget.modePrix,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  Future<void> _chargerGestion() async {
    try {
      final clients = await _gestionRepo.getClients();
      final commandes = await _gestionRepo.getCommandes();
      final notes = await _gestionRepo.getNotes();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _commandes = commandes;
        _notes = notes;
        _chargementGestion = false;
        _erreurGestion = null;
      });
    } catch (e) {
      // Sans ce filet, une erreur ici (ex : base locale plus récente que ce
      // que cette version de l'app sait ouvrir) laissait l'écran bloqué sur
      // le rond de chargement indéfiniment, sans aucun message.
      if (!mounted) return;
      setState(() {
        _chargementGestion = false;
        _erreurGestion = e.toString();
      });
    }
  }

  void _reessayerChargerGestion() {
    setState(() {
      _chargementGestion = true;
      _erreurGestion = null;
    });
    _chargerGestion();
  }

  /// Exécute une écriture Firestore (catalogue, client ou commande) et
  /// affiche l'erreur au lieu de la laisser silencieuse. Sans ce filet :
  /// Firestore applique l'écriture localement de façon optimiste (l'élément
  /// apparaît immédiatement dans les listes), puis l'annule dès que le
  /// serveur la rejette (droits insuffisants, document trop volumineux,
  /// perte réseau, etc.) — ce qui donnait l'impression que "ça marche une
  /// seconde puis ça disparaît", sans aucun message pour comprendre pourquoi.
  Future<bool> _ecrireFirestore(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'enregistrement : $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  bool _impressionCatalogueEnCours = false;

  Future<void> _imprimerCatalogue() async {
    setState(() => _impressionCatalogueEnCours = true);
    try {
      await Printing.layoutPdf(
        name: 'catalogue_${widget.tarif.name}.pdf',
        onLayout: (_) => genererCataloguePdf(
          tarif: widget.tarif,
          modePrix: widget.modePrix,
          familles: _familles,
          articles: _articles,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'impression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _impressionCatalogueEnCours = false);
    }
  }

  // --- Familles ---

  Future<String?> _demanderNomFamille({String? nomInitial}) async {
    final accent = widget.tarif.accentGradient;
    final controller = TextEditingController(text: nomInitial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          nomInitial == null ? 'Nouvelle famille' : 'Renommer la famille',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom de la famille',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent.last),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(nomInitial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Met une majuscule au début de chaque mot, sans toucher au reste (pour
  /// ne pas casser un sigle déjà en capitales, ex. "PET") — évite qu'un nom
  /// de famille tapé en minuscules s'affiche ainsi dans toute l'app.
  String _capitaliserMots(String texte) {
    return texte
        .split(' ')
        .map(
          (mot) => mot.isEmpty ? mot : mot[0].toUpperCase() + mot.substring(1),
        )
        .join(' ');
  }

  Future<void> _ajouterFamille() async {
    final saisie = await _demanderNomFamille();
    if (saisie == null || saisie.isEmpty) return;
    final nom = _capitaliserMots(saisie);
    final existeDeja = _familles.any(
      (f) => f.toLowerCase() == nom.toLowerCase(),
    );
    if (existeDeja) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"$nom" existe déjà')));
      return;
    }
    await _ecrireFirestore(() => _repo.ajouterFamille(nom));
  }

  Future<void> _modifierFamille(String ancienNom) async {
    final saisie = await _demanderNomFamille(nomInitial: ancienNom);
    if (saisie == null || saisie.isEmpty || saisie == ancienNom) return;
    final nom = _capitaliserMots(saisie);
    if (nom == ancienNom) return;
    final existeDeja = _familles.any(
      (f) => f.toLowerCase() == nom.toLowerCase() && f != ancienNom,
    );
    if (existeDeja) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"$nom" existe déjà')));
      return;
    }
    final succes = await _ecrireFirestore(
      () => _repo.renommerFamille(ancienNom, nom),
    );
    if (succes && _familleSelectionnee == ancienNom) {
      setState(() => _familleSelectionnee = nom);
    }
  }

  Future<void> _supprimerFamille(String nom) async {
    final nombreArticles = _articles.where((a) => a.categorie == nom).length;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette famille ?'),
        content: Text(
          nombreArticles > 0
              ? '"$nom" et ses $nombreArticles article${nombreArticles > 1 ? 's' : ''} seront supprimés.'
              : '"$nom" sera supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      final succes = await _ecrireFirestore(() => _repo.supprimerFamille(nom));
      if (succes && _familleSelectionnee == nom) {
        setState(() => _familleSelectionnee = null);
      }
    }
  }

  // --- Articles ---

  Future<void> _ajouterArticle() async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Article>(
      MaterialPageRoute(
        builder: (_) => ArticleFormScreen(
          accent: accent,
          famillesExistantes: _familles,
          familleInitiale: _familleSelectionnee,
        ),
      ),
    );
    if (resultat != null) {
      await _ecrireFirestore(() => _repo.ajouterArticle(resultat));
    }
  }

  Future<void> _modifierArticle(Article article) async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Article>(
      MaterialPageRoute(
        builder: (_) => ArticleFormScreen(
          accent: accent,
          famillesExistantes: _familles,
          articleExistant: article,
        ),
      ),
    );
    if (resultat != null) {
      await _ecrireFirestore(() => _repo.modifierArticle(resultat));
    }
  }

  Future<void> _supprimerArticle(Article article) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet article ?'),
        content: Text(article.designation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await _ecrireFirestore(() => _repo.supprimerArticle(article.id));
    }
  }

  // --- Clients ---

  Future<Client?> _ajouterClient() async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Client>(
      MaterialPageRoute(builder: (_) => ClientFormScreen(accent: accent)),
    );
    if (resultat != null) {
      final succes = await _ecrireFirestore(
        () => _gestionRepo.ajouterClient(resultat),
      );
      if (!succes) return null;
      setState(() {
        _clients = [..._clients, resultat]
          ..sort((a, b) => a.nomAffichage.compareTo(b.nomAffichage));
      });
    }
    return resultat;
  }

  Future<void> _modifierClient(Client client) async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) =>
            ClientFormScreen(accent: accent, clientExistant: client),
      ),
    );
    if (resultat != null) {
      final succes = await _ecrireFirestore(
        () => _gestionRepo.modifierClient(resultat),
      );
      if (succes) {
        setState(() {
          _clients = [
            for (final c in _clients) c.id == client.id ? resultat : c,
          ];
        });
      }
    }
  }

  Future<void> _supprimerClient(Client client) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: Text(client.nomAffichage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      final succes = await _ecrireFirestore(
        () => _gestionRepo.supprimerClient(client.id),
      );
      if (succes) {
        setState(() {
          _clients = _clients.where((c) => c.id != client.id).toList();
        });
      }
    }
  }

  // --- Panier / Commandes ---

  void _ajouterAuPanier(Article article) {
    final prix = widget.modePrix == ModePrix.detail
        ? article.prixDetail
        : article.prixGros;
    setState(() {
      final index = _panier.indexWhere((l) => l.articleId == article.id);
      if (index != -1) {
        _panier[index] = _panier[index].copyWith(
          quantite: _panier[index].quantite + 1,
        );
      } else {
        _panier.add(
          LigneCommande(
            articleId: article.id,
            designation: article.designation,
            prixUnitaire: prix,
            quantite: 1,
            codeArticle: article.codeArticle,
            codeBarre: article.codeBarre,
            colisage: article.colisage,
          ),
        );
      }
    });
    // Ouvre directement le panier pour que la quantité se règle sur place,
    // au lieu d'un simple message qui oblige à rouvrir le panier ensuite.
    _ouvrirPanier();
  }

  Future<void> _ouvrirPanier() async {
    final accent = widget.tarif.accentGradient;
    final client = await afficherPanier(
      context,
      lignes: _panier,
      accent: accent,
      onNouveauClient: _ajouterClient,
      clientsActuels: () => _clients,
    );
    if (client == null || !mounted) return;

    // Le récapitulatif (avec sa note facultative) s'affiche avant que la
    // commande ne soit réellement créée : le panier n'est vidé qu'après
    // confirmation, pour ne rien perdre si l'utilisateur revient en arrière.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommandeRecapScreen(
          client: client,
          lignes: List.of(_panier),
          tarif: widget.tarif,
          modePrix: widget.modePrix,
          onModifier: _modifierCommande,
          onConfirmer: (note, remisePourcent) async {
            final commande = Commande(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              clientId: client.id,
              clientNom: client.nomAffichage,
              date: DateTime.now(),
              modePrix: widget.modePrix,
              lignes: List.of(_panier),
              note: note,
              remisePourcent: remisePourcent,
            );
            await _gestionRepo.ajouterCommande(commande);
            if (mounted) {
              setState(() {
                _commandes = [commande, ..._commandes];
                _panier.clear();
              });
            }
            return commande;
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _modifierCommande(Commande commande) async {
    final accent = widget.tarif.accentGradient;
    await afficherEditionCommande(
      context,
      commande: commande,
      accent: accent,
      modePrix: widget.modePrix,
      articlesDisponibles: _articles,
      clientsActuels: () => _clients,
      onNouveauClient: _ajouterClient,
      onEnregistrer: (clientId, clientNom, lignes, note, remisePourcent) async {
        final misAJour = commande.copyWith(
          clientId: clientId,
          clientNom: clientNom,
          lignes: lignes,
          note: note,
          effacerNote: note == null,
          remisePourcent: remisePourcent,
        );
        await _gestionRepo.modifierCommande(misAJour);
        setState(() {
          _commandes = [
            for (final c in _commandes) c.id == commande.id ? misAJour : c,
          ];
        });
      },
    );
  }

  Future<void> _supprimerCommande(Commande commande) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette commande ?'),
        content: Text('Commande de ${commande.clientNom}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      final succes = await _ecrireFirestore(
        () => _gestionRepo.supprimerCommande(commande.id),
      );
      if (succes) {
        setState(() {
          _commandes = _commandes.where((c) => c.id != commande.id).toList();
        });
      }
    }
  }

  Future<void> _changerStatutCommande(
    Commande commande,
    StatutCommande statut,
  ) async {
    final misAJour = commande.copyWith(statut: statut);
    setState(() {
      _commandes = [
        for (final c in _commandes) c.id == commande.id ? misAJour : c,
      ];
    });
    try {
      await _gestionRepo.modifierCommande(misAJour);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commandes = [
          for (final c in _commandes) c.id == commande.id ? commande : c,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la mise à jour du statut : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Notes ---

  Future<void> _ajouterNote() async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(accent: accent, clients: _clients),
      ),
    );
    if (resultat != null) {
      await _gestionRepo.ajouterNote(resultat);
      setState(() {
        _notes = [resultat, ..._notes];
      });
    }
  }

  Future<void> _modifierNote(Note note) async {
    final accent = widget.tarif.accentGradient;
    final resultat = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(
          accent: accent,
          clients: _clients,
          noteExistante: note,
        ),
      ),
    );
    if (resultat != null) {
      await _gestionRepo.modifierNote(resultat);
      setState(() {
        _notes = [for (final n in _notes) n.id == note.id ? resultat : n];
      });
    }
  }

  Future<void> _supprimerNote(Note note) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: Text(
          note.contenu,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await _gestionRepo.supprimerNote(note.id);
      setState(() {
        _notes = _notes.where((n) => n.id != note.id).toList();
      });
    }
  }

  void _onFabPressed() {
    if (_selectedIndex == _indexClients) {
      _ajouterClient();
    } else if (_selectedIndex == _indexNotes) {
      _ajouterNote();
    } else if (!widget.isAdmin) {
      return;
    } else if (_familleSelectionnee == null) {
      _ajouterFamille();
    } else {
      _ajouterArticle();
    }
  }

  bool get _fabVisible {
    if (_chargement) return false;
    if (_selectedIndex == _indexClients || _selectedIndex == _indexNotes) {
      return true;
    }
    return _selectedIndex == _indexCatalogue && widget.isAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tarif.accentGradient;

    final Widget body;
    if (_chargement) {
      body = Center(child: CircularProgressIndicator(color: accent.last));
    } else if (_erreurGestion != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'Impossible de charger les clients/commandes/notes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _erreurGestion!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _reessayerChargerGestion,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    } else {
      switch (_selectedIndex) {
        case _indexPromotion:
          body = StatutArticlesView(
            statut: StatutArticle.promo,
            articles: _articlesPromo,
            modePrix: widget.modePrix,
            onTapArticle: (data) => _ouvrirCatalogueTarif(data.tarif),
          );
          break;
        case _indexNouveaute:
          body = StatutArticlesView(
            statut: StatutArticle.nouveaute,
            articles: _articlesNouveaute,
            modePrix: widget.modePrix,
            onTapArticle: (data) => _ouvrirCatalogueTarif(data.tarif),
          );
          break;
        case _indexStock:
          body = GestionStockView(
            articles: _articlesTous,
            modePrix: widget.modePrix,
            onTapArticle: (data) => _ouvrirCatalogueTarif(data.tarif),
          );
          break;
        case _indexClients:
          body = ClientsSection(
            tarif: widget.tarif,
            clients: _clients,
            onEdit: _modifierClient,
            onDelete: _supprimerClient,
            onAjouter: _ajouterClient,
            recherche: _rechercheClient,
            onRechercheChanged: (v) => setState(() => _rechercheClient = v),
          );
          break;
        case _indexCommandes:
          body = CommandesSection(
            tarif: widget.tarif,
            commandes: _commandes,
            clients: _clients,
            onEdit: _modifierCommande,
            onDelete: _supprimerCommande,
            onChangerStatut: _changerStatutCommande,
            recherche: _rechercheCommande,
            onRechercheChanged: (v) => setState(() => _rechercheCommande = v),
            filtreStatut: _filtreStatutCommande,
            onFiltreStatutChanged: (v) =>
                setState(() => _filtreStatutCommande = v),
          );
          break;
        case _indexNotes:
          body = NotesSection(
            tarif: widget.tarif,
            notes: _notes,
            onEdit: _modifierNote,
            onDelete: _supprimerNote,
            onAjouter: _ajouterNote,
          );
          break;
        default:
          body = CatalogueSection(
            tarif: widget.tarif,
            modePrix: widget.modePrix,
            articles: _articles,
            familles: _familles,
            familleSelectionnee: _familleSelectionnee,
            onFamilleSelectionnee: (f) =>
                setState(() => _familleSelectionnee = f),
            onEdit: _modifierArticle,
            onDelete: _supprimerArticle,
            onEditFamille: _modifierFamille,
            onDeleteFamille: _supprimerFamille,
            onAjouterPanier: _ajouterAuPanier,
            recherche: _rechercheArticle,
            onRechercheChanged: (v) => setState(() => _rechercheArticle = v),
            filtreStatut: _filtreStatut,
            onFiltreStatutChanged: (v) => setState(() => _filtreStatut = v),
            isAdmin: widget.isAdmin,
          );
      }
    }

    final panierCount = _panier.fold(0, (s, l) => s + l.quantite);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        final contenu = Column(
          children: [
            _TopBar(
              tarif: widget.tarif,
              modePrix: widget.modePrix,
              panierCount: panierCount,
              onOuvrirPanier: _ouvrirPanier,
              isAdmin: widget.isAdmin,
              onImprimerCatalogue: _imprimerCatalogue,
              impressionCatalogueEnCours: _impressionCatalogueEnCours,
            ),
            Expanded(child: body),
          ],
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecorativeBackground(
            child: SafeArea(
              bottom: !mobile,
              child: mobile
                  ? contenu
                  : Row(
                      children: [
                        SidebarNav(
                          items: _items,
                          selectedIndex: _selectedIndex,
                          onSelect: (i) => setState(() => _selectedIndex = i),
                          accent: accent,
                        ),
                        Expanded(child: contenu),
                      ],
                    ),
            ),
          ),
          bottomNavigationBar: mobile && !_chargement
              ? BottomNav(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  accent: accent,
                  primaryIndices: const [
                    _indexCatalogue,
                    _indexClients,
                    _indexCommandes,
                  ],
                )
              : null,
          floatingActionButton: _fabVisible
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: accent),
                    boxShadow: [
                      BoxShadow(
                        color: accent.last.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _onFabPressed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(
                      _selectedIndex == _indexClients
                          ? Icons.person_add_alt_1
                          : Icons.add,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final Tarif tarif;
  final ModePrix modePrix;
  final int panierCount;
  final VoidCallback onOuvrirPanier;
  final bool isAdmin;
  final VoidCallback onImprimerCatalogue;
  final bool impressionCatalogueEnCours;

  const _TopBar({
    required this.tarif,
    required this.modePrix,
    required this.panierCount,
    required this.onOuvrirPanier,
    required this.isAdmin,
    required this.onImprimerCatalogue,
    required this.impressionCatalogueEnCours,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tarif.accentGradient;
    return LayoutBuilder(
      builder: (context, constraints) {
        final etroit = constraints.maxWidth < 420;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 24, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3B5F)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tarif.nom,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: etroit ? 17 : 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B3B5F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: etroit ? 8 : 10,
                  vertical: etroit ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sell_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      etroit ? modePrix.libelleCourt : modePrix.libelle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: impressionCatalogueEnCours
                    ? null
                    : onImprimerCatalogue,
                icon: impressionCatalogueEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.print_outlined,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                tooltip: 'Imprimer le catalogue',
              ),
              const SizedBox(width: 2),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onOuvrirPanier,
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  if (panierCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: accent.last,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$panierCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!etroit) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _nomUtilisateurAffiche,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isAdmin)
                IconButton(
                  onPressed: () => afficherChangementMotDePasse(context),
                  icon: Icon(
                    Icons.lock_outline,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  tooltip: 'Changer mon mot de passe',
                ),
              IconButton(
                onPressed: () {
                  // CatalogueScreen est empilé par-dessus l'écran racine
                  // (AuthGate) via Navigator.push : sans ce popUntil, la
                  // déconnexion fonctionne en interne mais l'écran de
                  // connexion réapparaît caché derrière cet écran encore ouvert.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  AuthService.deconnecter();
                },
                icon: Icon(
                  Icons.logout,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                tooltip: 'Se déconnecter',
              ),
            ],
          ),
        );
      },
    );
  }

  String get _nomUtilisateurAffiche {
    final email = AuthService.utilisateurActuel?.email ?? '';
    return email.split('@').first;
  }
}
