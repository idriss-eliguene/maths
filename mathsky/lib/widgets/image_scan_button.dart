// pubspec.yaml additions:
// dependencies:
//   image_picker: ^1.0.4
//   google_ml_kit: ^0.16.2

// lib/widgets/image_scan_button.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ImageScanButton extends StatelessWidget {
  final void Function(String) onTextRecognized;
  final IconData icon;
  final String label;

  const ImageScanButton({
    super.key,
    required this.onTextRecognized,
    required this.icon,
    required this.label,
  });

  Future<void> _pickAndScanImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await recognizer.processImage(inputImage);
    await recognizer.close();

    onTextRecognized(recognizedText.text);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon),
          tooltip: label,
          onPressed: () => _pickAndScanImage(ImageSource.gallery),
        ),
      ],
    );
  }
}