import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/home/home_shell_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final preferences = await SharedPreferences.getInstance();
  final themeMode = preferences.getBool('is_light_mode') ?? false;

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(SnapPriceApp(
    preferences: preferences,
    initialThemeMode: themeMode ? ThemeMode.light : ThemeMode.dark,
  ));
}

class SnapPriceApp extends StatefulWidget {
  const SnapPriceApp({
    super.key,
    required this.preferences,
    required this.initialThemeMode,
  });

  final SharedPreferences preferences;
  final ThemeMode initialThemeMode;

  @override
  State<SnapPriceApp> createState() => _SnapPriceAppState();
}

class _SnapPriceAppState extends State<SnapPriceApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  Future<void> _setThemeMode(ThemeMode value) async {
    await widget.preferences.setBool('is_light_mode', value == ThemeMode.light);
    setState(() => _themeMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapPrice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1),
          ),
          child: child!,
        );
      },
      home: AppConfig.isConfigured
          ? _AuthGate(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            )
          : _ConfigurationScreen(themeMode: _themeMode),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<Session?>(
      initialData: client.auth.currentSession,
      stream: client.auth.onAuthStateChange.map((event) => event.session),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return AuthScreen(
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
          );
        }

        return HomeShellScreen(
          themeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged,
        );
      },
    );
  }
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SnapPrice is waiting for public runtime keys.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start the app with --dart-define values for ${AppConfig.missingKeys.join(', ')}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OpenAI and Stripe secret keys belong only in Supabase Edge Function secrets, never in Flutter.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
