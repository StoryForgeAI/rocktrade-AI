import 'package:flutter/foundation.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const mobileOAuthRedirect = String.fromEnvironment(
    'SUPABASE_MOBILE_REDIRECT',
    defaultValue: 'com.example.snapprice://login-callback',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static List<String> get missingKeys {
    final keys = <String>[];
    if (supabaseUrl.isEmpty) keys.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) keys.add('SUPABASE_ANON_KEY');
    return keys;
  }

  static String? get oauthRedirectTo {
    if (kIsWeb) {
      return null;
    }
    return mobileOAuthRedirect;
  }
}
