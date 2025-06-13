import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../utils/text_cleaner.dart';

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

  Future<void> _pickAndScanImage(ImageSource source, BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await recognizer.processImage(inputImage);
    await recognizer.close();

    final expression = cleanOCRText(recognizedText.text);

    if (!isLikelyMathExpression(expression)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune expression mathématique détectée.")),
      );
      return;
    }

    onTextRecognized(expression);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon),
          tooltip: label,
          onPressed: () => _pickAndScanImage(ImageSource.gallery, context),
        ),
      ],
    );
  }
}
