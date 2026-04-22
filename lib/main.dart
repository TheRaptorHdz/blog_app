import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'core/auth_wrapper.dart';
import 'firebase_options.dart';   
import 'package:blog_app/features/blog/screens/home_screen.dart';

// Handler para mensajes cuando la app está en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("📩 Mensaje en background: ${message.notification?.title}");
}

Future<void> setupFCM() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicitar permisos de notificación
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Obtener token FCM
  String? token = await messaging.getToken();
  print("🔑 FCM Token: $token");

  // Guardar token en Firestore
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Actualizar token cuando se refresca
  messaging.onTokenRefresh.listen((newToken) async {
    print("🔄 Token actualizado: $newToken");
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'fcmToken': newToken});
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar handler para background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Configurar FCM
  await setupFCM();
  // Escuchar notificaciones cuando la app está en primer plano (foreground)
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print("📩 Notificación en foreground: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");

  // Aquí puedes mostrar un SnackBar, Dialog, o usar flutter_local_notifications
});

// Opcional: Cuando la app está en background y el usuario toca la notificación
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print("Notificación abierta desde background");
  // Aquí puedes navegar al blog usando message.data['blogId']
});

  runApp(const MyApp());   // ← Aquí está el problema
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),           // ← Cambia si tu pantalla inicial es otra
      routes: {
        '/home': (context) => const HomeScreen(),
        // Puedes agregar más rutas aquí
      },
    );
  }
}