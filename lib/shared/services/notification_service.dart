import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  /// Crea una notificación en Firestore
  Future<void> createNotification({
    required String toUserId,
    required String fromUserName,
    required String type, // "comment" o "reply"
    required String blogId,
    required String text,
  }) async {
    if (toUserId.isEmpty) return;

    try {
      await _db.collection('notifications').add({
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'type': type,
        'blogId': blogId,
        'text': text,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      print('Error al crear notificación: $e');
    }
  }
}