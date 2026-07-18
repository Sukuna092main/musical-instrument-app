import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/settings/app_settings.dart';
import 'core/settings/app_settings_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'l10n/generated/app_localizations.dart';

class MusicPracticeApp extends StatefulWidget {
  const MusicPracticeApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<MusicPracticeApp> createState() => _MusicPracticeAppState();
}

class _MusicPracticeAppState extends State<MusicPracticeApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;

    return MaterialApp(
      title: 'Music Practice Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          AppSettingsScope(settings: settings, child: child!),
      home: const SplashScreen(),
    );
  }
}
