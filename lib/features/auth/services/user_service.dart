import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Crea los datos del usuario después del registro
  /// Ahora acepta el nombre que el usuario escribió en el formulario
  Future<void> createUserData({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),           // ← Nombre que el usuario escribió
        'email': user.email,
        'photoUrl': null,
        'createdAt': Timestamp.now(),
        'fcmToken': null,              // Se llenará después con FCM
      }, SetOptions(merge: true));

      print('✅ Usuario creado correctamente en Firestore');
    } catch (e) {
      print('Error al crear datos de usuario: $e');
      rethrow;
    }
  }

  /// Actualiza el perfil (ya lo tenías, lo dejo igual)
  Future<void> updateProfile(String name, String? photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      Map<String, dynamic> data = {'name': name.trim()};

      if (photoUrl != null) {
        data['photoUrl'] = photoUrl;
      }

      await _db.collection('users').doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error al actualizar perfil: $e');
      rethrow;
    }
  }
}