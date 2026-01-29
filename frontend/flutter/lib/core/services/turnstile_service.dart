import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import '../config/turnstile_config.dart';

/// Service pour gérer les tokens Cloudflare Turnstile en mode invisible
class TurnstileService {
  /// Instance singleton pour l'injection de dépendances
  static TurnstileService? _instance;
  static TurnstileService get instance => _instance ??= TurnstileService._();

  /// Pour les tests : permet d'injecter un mock
  static set instance(TurnstileService service) => _instance = service;

  /// Pour les tests : réinitialise l'instance
  @visibleForTesting
  static void resetInstance() => _instance = null;

  TurnstileService._();

  /// Récupère un nouveau token Turnstile.
  /// Chaque appel génère un nouveau token (usage unique).
  Future<String?> getToken() async {
    final turnstile = CloudflareTurnstile.invisible(
      siteKey: TurnstileConfig.siteKey,
      baseUrl: TurnstileConfig.baseUrl,
    );

    try {
      debugPrint('🔐 Requesting Turnstile token...');
      final token = await turnstile.getToken();
      debugPrint('✅ Turnstile token received');
      return token;
    } on TurnstileException catch (e) {
      debugPrint('❌ Turnstile challenge failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Turnstile error: $e');
      return null;
    } finally {
      turnstile.dispose();
    }
  }
}
