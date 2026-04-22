import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/user_service.dart';
import '../../blog/services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  File? selectedImage;

  String? currentPhotoUrl;

  final ImageService _imageService = ImageService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // 📥 cargar datos actuales
  void loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data();

    if (data != null) {
      setState(() {
        nameController.text = data['name'] ?? '';
        currentPhotoUrl = data['photoUrl'];
      });
    }
  }

  // 📸 seleccionar imagen
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // 💾 guardar perfil
  void saveProfile() async {
    String? imageUrl;

    if (selectedImage != null) {
      print("Subiendo imagen...");
      imageUrl = await _imageService.uploadImage(selectedImage!);
      print("URL: $imageUrl");
    }

    await _userService.updateProfile(
      nameController.text.trim(),
      imageUrl,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final hasValidPhoto =
        currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 Imagen
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : hasValidPhoto
                        ? NetworkImage(currentPhotoUrl!)
                        : null,
                child: selectedImage == null && !hasValidPhoto
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            Text(user?.email ?? ''),

            const SizedBox(height: 10),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}