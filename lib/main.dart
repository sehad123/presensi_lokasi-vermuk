import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:presensi_app/firebase_setup.dart';
import 'package:presensi_app/home/home_page.dart';
import 'package:presensi_app/notification_helper.dart';
import 'package:presensi_app/splash_screen.dart';
import 'package:presensi_app/login/login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Firebase secara manual dengan mengonfirmasi hasilnya
    final FirebaseApp firebaseApp = await Firebase.initializeApp();

    // Verifikasi inisialisasi
    if (firebaseApp != null) {
      print('Firebase initialized successfully');

      // Jalankan setupFirebase setelah Firebase berhasil diinisialisasi
      await setupFirebase();

      // Tes koneksi Firestore
      await testFirestoreConnection();
      // Inisialisasi Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationHelper notificationHelper = NotificationHelper();

      // Minta izin notifikasi (untuk iOS)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission for notifications');
      } else {
        print('User denied notification permission');
      }

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      String? token = await messaging.getToken();
      print('FCM Token: $token');

      // Handler pesan foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          notificationHelper.showNotification(
            message.notification!.title ?? 'Presensi',
            message.notification!.body ?? 'Jangan lupa melakukan presensi!',
          );
        }
      });
    } else {
      print('Failed to initialize Firebase');
    }
  } catch (e) {
    print('Unexpected error during initialization: $e');
  }

  runApp(const MyApp());
}

Future<void> testFirestoreConnection() async {
  try {
    var testDoc = await FirebaseFirestore.instance
        .collection('test')
        .doc('connection')
        .get();
    print(
        'Firestore connection test: ${testDoc.exists ? 'Success' : 'Failed'}');
  } catch (e) {
    print('Error testing Firestore connection: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presensi APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handling for different routes
        switch (settings.name) {
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => HomePage(
                userId: args?['userId'] ?? '',
              ),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          default:
            return MaterialPageRoute(builder: (context) => SplashScreen());
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('404'),
            ),
            body: Center(
              child: Text('Page not found!'),
            ),
          ),
        );
      },
    );
  }
}
