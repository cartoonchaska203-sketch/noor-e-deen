import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/state/app_state.dart';
import 'core/widgets/app_error_widget.dart';

/// Entry point for Noor-e-Deen (Phase 1).
///
/// Global error handling is installed here so that no unhandled framework
/// error can crash the app: errors are logged and a friendly fallback widget
/// is shown instead of the red screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Noor-e-Deen FlutterError: ${details.exception}');
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const AppErrorWidget();
  };

  final appState = AppState.instance;
  await appState.load();

  // Best-effort locale data for date formatting; failures fall back to 'en'.
  try {
    await initializeDateFormatting('en', null);
  } catch (_) {
    /* ignore */
  }
  try {
    await initializeDateFormatting('ur', null);
  } catch (_) {
    /* ignore */
  }

  runApp(
    AppStateScope(
      notifier: appState,
      child: const NoorApp(),
    ),
  );
}
