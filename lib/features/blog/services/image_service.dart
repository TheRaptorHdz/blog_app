import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageService {
  final String apiKey = '9bba7a6379de77a3567ce9b4ea6b9116';

  Future<String?> uploadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey"),
      body: {
        "image": base64Image,
      },
    );

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  print(data); // 👈 DEBUG

  return data["data"]["url"];
} else {
  print("Error: ${response.body}");
  return null;
}
  }
}