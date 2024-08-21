import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  NotificationHelper() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Inisialisasi Awesome Notifications
    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'presensi_channel',
          channelName: 'Waktunya Presensi!',
          channelDescription:
              'Saatnya untuk melakukan presensi untuk jadwal kuliah Anda.',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
    );
  }

  Future<void> showNotification(String title, String body) async {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // ID unik
        channelKey: 'presensi_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        largeIcon: 'resource://mipmap/ic_launcher',
      ),
    );
  }
}
