import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageScanButton extends StatefulWidget {
  final void Function(String text) onTextScanned;

  const ImageScanButton({super.key, required this.onTextScanned});

  @override
  State<ImageScanButton> createState() => _ImageScanButtonState();
}

class _ImageScanButtonState extends State<ImageScanButton> {
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _loading = true);

    try {
      final uri = Uri.parse("http://51.75.117.209:5000/scan"); // remplace par ton IP/API si besoin
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath("image", image.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = json.decode(body);

      if (response.statusCode == 200 && data["text"] != null) {
        final rawText = data["text"].toString().trim();

        // Vérifie si le texte semble valide
        if (rawText.isEmpty || rawText.toLowerCase().contains("error")) {
          _showError("Texte OCR invalide. Réessayez avec une image plus claire.");
        } else {
          final cleaned = _cleanMathInput(rawText);
          widget.onTextScanned(cleaned);
        }
      } else {
        _showError("Échec de la lecture OCR.");
      }
    } catch (e) {
      _showError("Erreur : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  String _cleanMathInput(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9xX^+\-*/().= ]'), '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
          )
        : IconButton(
            tooltip: "Scanner une image",
            icon: const Icon(Icons.image_search),
            onPressed: _pickImage,
          );
  }
}
