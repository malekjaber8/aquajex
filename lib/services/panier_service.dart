import '../models/commande.dart';

/// Panier partagé entre les deux catalogues (Aquajex et Les Cinq Frères) :
/// une seule liste, commune à toute la session, pour que passer de l'un à
/// l'autre catalogue ne vide pas ce qui a déjà été ajouté — permet de
/// composer une même commande avec des articles des deux gammes.
class PanierService {
  PanierService._();

  static final List<LigneCommande> lignes = [];
}
