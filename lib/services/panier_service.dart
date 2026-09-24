import '../models/commande.dart';
import '../models/mode_prix.dart';
import '../models/tarif.dart';

/// Un panier par catalogue (Aquajex / Les Cinq Frères), qui survit à la
/// navigation.
///
/// `CatalogueScreen` recrée une toute nouvelle instance à chaque fois qu'on
/// y accède (Navigator.push) : un panier stocké dans son State local était
/// donc perdu dès qu'on revenait à l'accueil puis qu'on rouvrait le même
/// catalogue. En le stockant ici (statique, propre à chaque tarif), il
/// reste rempli tant qu'aucune commande n'a été confirmée pour ce
/// catalogue — voir CatalogueScreen._panier.
class PanierService {
  PanierService._();

  static final Map<Tarif, List<LigneCommande>> _paniers = {
    for (final t in Tarif.values) t: <LigneCommande>[],
  };

  // Mode de prix (détail/gros) sous lequel le panier de chaque tarif a été
  // rempli. Un panier ne doit jamais contenir des lignes ajoutées sous deux
  // modes différents, sinon la facture mélange prix détail et prix gros
  // pour un même bon de commande.
  static final Map<Tarif, ModePrix?> _modes = {
    for (final t in Tarif.values) t: null,
  };

  static List<LigneCommande> pour(Tarif tarif) => _paniers[tarif]!;

  /// À appeler à l'ouverture d'un catalogue, avant tout ajout au panier.
  /// Si le panier existant a été rempli sous un autre mode de prix (le
  /// commercial a changé le badge "Tarif : détail/gros" entre deux visites
  /// du même catalogue), on le vide plutôt que de risquer un mélange de
  /// prix dans la commande. Retourne true si le panier a dû être vidé.
  static bool assurerMode(Tarif tarif, ModePrix mode) {
    final modePrecedent = _modes[tarif];
    _modes[tarif] = mode;
    if (modePrecedent != null &&
        modePrecedent != mode &&
        _paniers[tarif]!.isNotEmpty) {
      _paniers[tarif]!.clear();
      return true;
    }
    return false;
  }

  /// Vide les deux paniers — appelé à la déconnexion pour qu'un autre
  /// compte se connectant ensuite sur le même appareil n'hérite pas du
  /// panier du précédent.
  static void viderTout() {
    for (final lignes in _paniers.values) {
      lignes.clear();
    }
    for (final t in Tarif.values) {
      _modes[t] = null;
    }
  }
}
