import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/blog_service.dart';
import '../../auth/widgets/user_info_widget.dart';
import '../../auth/screens/profile_screen.dart';
import '../../blog/screens/comment_screen.dart';
import 'create_blog_screen.dart';
import '../../blog/screens/notification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Column(
        children: [
          // ==================== HEADER PERSONALIZADO ====================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(height: 80);
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final String name = userData['name'] ?? 'Usuario';
              final String? photoUrl = userData['photoUrl'];

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // 👤 FOTO
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),

                    const SizedBox(width: 10),

                    // 🧑 NOMBRE
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 🔔 NOTIFICACIONES
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),

                    // 👤 PERFIL
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),

                    // 🚪 LOGOUT
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cerrar sesión'),
                            content: const Text('¿Seguro que quieres salir?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text(
                                  'Salir',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // ==================== LISTA DE BLOGS ====================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blogs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final blogs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: blogs.length,
                  itemBuilder: (context, index) {
                    final blog = blogs[index];
                    final data = blog.data() as Map<String, dynamic>;

                    final String title = data['title'] ?? 'Sin título';
                    final String content = data['content'] ?? '';
                    final String? imageUrl = data['imageUrl'];
                    final List<dynamic> likes = data['likes'] ?? [];
                    final int totalCommentCount =
                        (data['totalCommentCount'] as num?)?.toInt() ?? 0;

                    final bool isLiked =
                        likes.contains(currentUser?.uid);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.05),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          UserInfoWidget(
                              userId: data['userId'] ?? ''),

                          const SizedBox(height: 10),

                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          if (imageUrl != null &&
                              imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              // ❤️ LIKE
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        BlogService()
                                            .toggleLike(blog.id),
                                    icon: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    likes.length.toString(),
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ],
                              ),

                              // 💬 COMENTARIOS
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.comment_outlined),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CommentScreen(
                                                  blogId:
                                                      blog.id),
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    totalCommentCount.toString(),
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ],
                              ),

                              // 🔗 SHARE
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ NUEVO POST
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateBlogScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}