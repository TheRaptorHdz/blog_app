import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoWidget extends StatelessWidget {
  final String userId;

  const UserInfoWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Row(
        children: [
          CircleAvatar(radius: 15),
          SizedBox(width: 8),
          Text("Cargando..."),
        ],
      );
    }

    final data = snapshot.data!.data() as Map<String, dynamic>?;

    final name = data?['name'] ?? 'Usuario';
    final photoUrl = data?['photoUrl'];
    final hasValidPhoto =
        photoUrl != null && photoUrl.toString().isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage:
              hasValidPhoto ? NetworkImage(photoUrl) : null,
          child: !hasValidPhoto
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  },
);
  }
}
