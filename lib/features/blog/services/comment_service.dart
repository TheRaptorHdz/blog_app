import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blog_app/shared/services/notification_service.dart';

class CommentService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ==================== ADD COMMENT ====================
  Future<void> addComment(String blogId, String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final String userName = userData?['name'] ?? user.email ?? 'Usuario Anónimo';

      final blogRef = _db.collection('blogs').doc(blogId);

      await blogRef.collection('comments').add({
        'text': text.trim(),
        'userId': user.uid,
        'userName': userName,
        'likes': [],
        'createdAt': Timestamp.now(),
      });

      // Incrementar contadores
      await blogRef.update({
        'commentCount': FieldValue.increment(1),
        'totalCommentCount': FieldValue.increment(1),
      });

      // Notificación al dueño del post
      final blogDoc = await blogRef.get();
      final blogData = blogDoc.data();
      final String? postOwnerId = blogData?['userId'];

      if (postOwnerId != null && postOwnerId != user.uid) {
        await NotificationService().createNotification(
          toUserId: postOwnerId,
          fromUserName: userName,
          type: "comment",
          blogId: blogId,
          text: text.trim(),
        );
      }
    } catch (e) {
      print('Error al agregar comentario: $e');
      rethrow;
    }
  }

  // ==================== TOGGLE LIKE EN COMENTARIO ====================
  Future<void> toggleLikeComment(String blogId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ref = _db
          .collection('blogs')
          .doc(blogId)
          .collection('comments')
          .doc(commentId);

      final doc = await ref.get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      List<dynamic> likes = List.from(data['likes'] ?? []);

      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await ref.update({'likes': likes});
    } catch (e) {
      print('Error al dar like al comentario: $e');
    }
  }

  // ==================== ADD REPLY ====================
  Future<void> addReply(String blogId, String commentId, String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final String userName = userData?['name'] ?? user.email ?? 'Usuario Anónimo';

      await _db
          .collection('blogs')
          .doc(blogId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add({
        'text': text.trim(),
        'userName': userName,
        'createdAt': Timestamp.now(),
      });

      // Incrementar total de comentarios
      final blogRef = _db.collection('blogs').doc(blogId);
      await blogRef.update({
        'totalCommentCount': FieldValue.increment(1),
      });

      // Notificación al dueño del comentario
      final commentDoc = await _db
          .collection('blogs')
          .doc(blogId)
          .collection('comments')
          .doc(commentId)
          .get();

      final commentData = commentDoc.data();
      final String? commentOwnerId = commentData?['userId'];

      if (commentOwnerId != null && commentOwnerId != user.uid) {
        await NotificationService().createNotification(
          toUserId: commentOwnerId,
          fromUserName: userName,
          type: "reply",
          blogId: blogId,
          text: text.trim(),
        );
      }
    } catch (e) {
      print('Error al agregar respuesta: $e');
    }
  }
}