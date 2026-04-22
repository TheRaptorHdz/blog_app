import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver notificaciones')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notificaciones")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
  if (snapshot.hasError) {
    return Center(
      child: Text('Error: ${snapshot.error}'),
    );
  }

  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return const Center(
      child: Text('No tienes notificaciones aún'),
    );
  }

  final notifications = snapshot.data!.docs;

  return ListView.builder(
    itemCount: notifications.length,
    itemBuilder: (context, index) {
      final notif = notifications[index];
      final data = notif.data() as Map<String, dynamic>;

      final bool isRead = data['isRead'] ?? false;

      return ListTile(
        leading: Icon(
          Icons.notifications,
          color: isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(
          "${data['fromUserName']} ${data['type'] == 'comment' ? 'comentó tu post' : 'respondió a tu comentario'}",
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(data['text'] ?? ''),
        onTap: () {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notif.id)
              .update({'isRead': true});
        },
      );
    },
  );
}
      ),
    );
  }
}