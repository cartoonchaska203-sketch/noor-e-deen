import 'package:flutter/material.dart';

import '../../core/services/connectivity/connectivity_service.dart';
import '../../l10n/strings.dart';

/// Banner shown at the top of features that need the internet
/// (mosque finder, audio streaming, video links, live Zakat rates).
///
/// Rebuilds automatically when connectivity changes. Fully offline
/// features (prayer times, Qibla, Tasbeeh, bundled Quran/Duas,
/// Salah guide) never show this banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.onChange,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, snap) {
        final online = snap.data ?? true;
        if (online) return const SizedBox.shrink();
        return Semantics(
          liveRegion: true,
          label: S.of(context, 'offline_banner_semantics'),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context)
                .colorScheme
                .errorContainer,
            child: Row(
              children: [
                Icon(Icons.wifi_off,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message ?? S.of(context, 'offline_banner'),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
