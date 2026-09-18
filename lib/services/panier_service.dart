import '../models/commande.dart';
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

  static List<LigneCommande> pour(Tarif tarif) => _paniers[tarif]!;

  /// Vide les deux paniers — appelé à la déconnexion pour qu'un autre
  /// compte se connectant ensuite sur le même appareil n'hérite pas du
  /// panier du précédent.
  static void viderTout() {
    for (final lignes in _paniers.values) {
      lignes.clear();
    }
  }
}
