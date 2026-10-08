import 'package:flutter/foundation.dart';

import 'ai/noor_ai_service.dart';
import 'notifications/local_notification_service.dart';
import 'notifications/notification_service.dart';
import 'sync/cloud_sync_service.dart';

/// Central access point for Phase 4 services.
///
/// Initialized once in main(). On platforms where local notifications
/// cannot run, [notifications] falls back to [DisabledNotificationService]
/// so the rest of the app keeps working.
class AppServices {
  AppServices._();

  static NotificationService notifications = DisabledNotificationService();
  static CloudSyncService sync = StubCloudSyncService();
  static NoorAiService noorAi = LocalNoorAiService();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final local = LocalNotificationService.instance;
      await local.init();
      if (await local.isSupported) {
        notifications = local;
      }
    } catch (e) {
      debugPrint('Noor-e-Deen AppServices notification init failed: $e');
      notifications = DisabledNotificationService();
    }
    sync = LocalFirstSyncService();
  }
}
