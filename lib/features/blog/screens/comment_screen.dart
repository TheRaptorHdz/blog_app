import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/comment_service.dart';

class CommentScreen extends StatefulWidget {
  final String blogId;

  const CommentScreen({super.key, required this.blogId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final controller = TextEditingController();
  final CommentService _commentService = CommentService();

  void sendComment() async {
    if (controller.text.trim().isEmpty) return;

    await _commentService.addComment(
      widget.blogId,
      controller.text.trim(),
    );

    controller.clear();
  }

  // Diálogo para responder a un comentario
  void _showReplyDialog(String commentId) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Responder"),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              hintText: "Escribe tu respuesta...",
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                final text = replyController.text.trim();
                if (text.isNotEmpty) {
                  await _commentService.addReply(
                    widget.blogId,
                    commentId,
                    text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blogs')
                  .doc(widget.blogId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final data = comment.data() as Map<String, dynamic>;

                    // Datos para likes
                    final List<dynamic> likes = data['likes'] ?? [];
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final bool isLiked = likes.contains(currentUser?.uid);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            data['userName'] ?? 'Usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(data['text'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  _commentService.toggleLikeComment(
                                    widget.blogId,
                                    comment.id,
                                  );
                                },
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                              ),
                              Text(likes.length.toString()),
                            ],
                          ),
                        ),

                        // Botón "Responder"
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: TextButton.icon(
                            onPressed: () => _showReplyDialog(comment.id),
                            icon: const Icon(Icons.reply, size: 20),
                            label: const Text("Responder"),
                          ),
                        ),

                        // Mostrar Replies (respuestas)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('blogs')
                              .doc(widget.blogId)
                              .collection('comments')
                              .doc(comment.id)
                              .collection('replies')
                              .orderBy('createdAt', descending: false)
                              .snapshots(),
                          builder: (context, replySnapshot) {
                            if (!replySnapshot.hasData || replySnapshot.data!.docs.isEmpty) {
                              return const SizedBox();
                            }

                            final replies = replySnapshot.data!.docs;

                            return Column(
                              children: replies.map((reply) {
                                final replyData = reply.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 56, right: 16, top: 2, bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.subdirectory_arrow_right,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${replyData['userName'] ?? 'Usuario'}: ",
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: replyData['text'] ?? '',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const Divider(height: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input para nuevo comentario
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  onPressed: sendComment,
                  icon: const Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}