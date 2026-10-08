import 'package:flutter/material.dart';

/// Friendly full-screen fallback shown when a widget build fails.
/// Installed via ErrorWidget.builder in main.dart so the app never shows
/// a red screen or crashes to the OS.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48),
                SizedBox(height: 12),
                Text(
                  'Something went wrong while drawing this screen.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please restart the app. Your settings are safe.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
