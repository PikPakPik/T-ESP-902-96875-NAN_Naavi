import 'package:flutter_dotenv/flutter_dotenv.dart';

class TurnstileConfig {
  static String get siteKey {
    final key = dotenv.env['TURNSTILE_SITE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'TURNSTILE_SITE_KEY est requis dans le fichier .env\n'
        'Ajoutez: TURNSTILE_SITE_KEY=votre_site_key',
      );
    }
    return key;
  }

  static String get baseUrl {
    final url = dotenv.env['TURNSTILE_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'TURNSTILE_BASE_URL est requis dans le fichier .env\n'
        'Ajoutez: TURNSTILE_BASE_URL=https://naavi-trails.fr/',
      );
    }
    return url;
  }
}
