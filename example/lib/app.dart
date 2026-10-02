import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:video_flux/video_flux.dart';

import 'app_dependencies.dart';
import 'features/feed/presentation/pages/feed_page.dart';
import 'l10n/app_localizations.dart';

/// The example app. Pass [controllerFactory] to use another player or a fake.
class VideoFluxExampleApp extends StatefulWidget {
  /// Creates the app.
  const VideoFluxExampleApp({
    this.controllerFactory,
    this.pageLatency = const Duration(milliseconds: 300),
    super.key,
  });

  /// Creates a backend controller per video.
  final VideoControllerFactory? controllerFactory;

  /// How long a simulated page takes to arrive.
  final Duration pageLatency;

  @override
  State<VideoFluxExampleApp> createState() => _VideoFluxExampleAppState();
}

class _VideoFluxExampleAppState extends State<VideoFluxExampleApp> {
  late final AppDependencies _dependencies = AppDependencies(
    controllerFactory: widget.controllerFactory,
    pageLatency: widget.pageLatency,
  );

  late Locale _locale =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar'
          ? const Locale('ar')
          : const Locale('en');

  void _toggleLanguage() => setState(
        () => _locale = _locale.languageCode == 'en'
            ? const Locale('ar')
            : const Locale('en'),
      );

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appTitle,
        theme: ThemeData.dark(useMaterial3: true),
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FeedPage(
          dependencies: _dependencies,
          onToggleLanguage: _toggleLanguage,
        ),
      );
}
