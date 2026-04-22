import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class BlogService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Crea un nuevo blog con los contadores inicializados
  Future<void> createBlog(
    String title,
    String content,
    String? imageUrl,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('blogs').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'likes': [],
        'commentCount': 0,           // ← Contador de comentarios principales
        'totalCommentCount': 0,      // ← Total (comentarios + respuestas)
      });
    } catch (e) {
      print('Error al crear blog: $e');
      rethrow;
    }
  }

  /// Alterna el like en un blog
  Future<void> toggleLike(String blogId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _db.collection('blogs').doc(blogId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      List<dynamic> likes = List.from(data['likes'] ?? []);

      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await docRef.update({'likes': likes});
    } catch (e) {
      print('Error al dar like al blog: $e');
    }
  }
}