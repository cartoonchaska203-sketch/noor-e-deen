import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';

/// Root widget: wires theme mode, locale and the bottom-navigation shell.
class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bool isLight = state.themeMode == AppThemeMode.light;

    return MaterialApp(
      title: 'Noor-e-Deen',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      darkTheme: state.themeMode == AppThemeMode.amoled
          ? AppThemes.amoled()
          : AppThemes.dark(),
      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
      locale: Locale(state.localeCode),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
