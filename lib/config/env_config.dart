import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API URL
  static String get apiUrl {
    final url = dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'API_URL environment variable is not set. Please check your .env file.',
      );
    }
    return url;
  }
}
