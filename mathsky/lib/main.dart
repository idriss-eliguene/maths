import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyMathSolverApp());
}

class MyMathSolverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Math Solver',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: MathHomePage(),
    );
  }
}

class MathHomePage extends StatefulWidget {
  @override
  _MathHomePageState createState() => _MathHomePageState();
}

class _MathHomePageState extends State<MathHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _solution = '';
  String _errorMessage = '';
  bool _isLoading = false;

  // OCR Functionality
  String _recognizedText = '';

  Future<void> _pickAndRecognizeText() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        setState(() {
          _recognizedText = recognizedText.text;
          _controller.text = _recognizedText; // Remplit le champ avec l’OCR
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur OCR : $e';
      });
    }
  }

  Future<void> _solveProblem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _solution = '';
    });
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.200:5000/solve'), // Remplace par ton IP locale
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'problem': _controller.text}),
      );

      print('DEBUG: HTTP Response Code: ${response.statusCode}');
      print('DEBUG: HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _solution = json.decode(response.body)['solution'];
        });
      } else {
        setState(() {
          _errorMessage =
              'Erreur serveur : ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Math Solver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Écris ton problème mathématique',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _pickAndRecognizeText,
                ),
              ),
              maxLines: null,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _solveProblem,
              icon: Icon(Icons.calculate),
              label: Text('Résoudre'),
            ),
            SizedBox(height: 16),
            if (_isLoading) CircularProgressIndicator(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            if (_solution.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 16.0),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Solution :',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(_solution),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
