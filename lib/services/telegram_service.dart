import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Notification Telegram envoyée à l'admin à chaque commande enregistrée
/// par un commercial (pas par l'admin lui-même, voir
/// `CatalogueScreen._notifierTelegram`).
///
/// Utilise directement l'API Bot Telegram (`sendMessage`) depuis l'app :
/// pas de Cloud Function, pour rester sur le plan Firebase gratuit (Spark),
/// comme pour le reste de l'app — voir mémoire architecture.
class TelegramService {
  TelegramService._();

  // Jeton du bot (@BotFather) et identifiant du groupe Telegram "Aquajex
  // application" à notifier — quiconque est ajouté/retiré de ce groupe
  // reçoit ou non les notifications, sans toucher au code.
  static const _botToken = '8870039849:AAFFk52-hzmfXNBpmoD6m1Umh8qY-zM0lpI';
  static const _chatId = '-5317979459';

  static Future<void> notifierNouvelleCommande({
    required String nomCommercial,
    required String clientNom,
    required String tarifNom,
    required double totalTtc,
  }) async {
    if (_botToken.isEmpty || _chatId.isEmpty) return;

    final texte =
        '🛒 Nouvelle commande\n'
        'Commercial : $nomCommercial\n'
        'Client : $clientNom\n'
        'Catalogue : $tarifNom\n'
        'Total : ${totalTtc.toStringAsFixed(3)} DT';

    try {
      final reponse = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        body: {'chat_id': _chatId, 'text': texte},
      );
      if (reponse.statusCode != 200) {
        debugPrint(
          '[Telegram] échec (${reponse.statusCode}) : ${reponse.body}',
        );
      }
    } catch (e) {
      // Une notification manquée ne doit jamais faire échouer la commande
      // elle-même côté commercial — juste tracée pour diagnostic.
      debugPrint('[Telegram] échec de l\'envoi : $e');
    }
  }
}
