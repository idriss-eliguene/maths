import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
  List<String> _steps = [];
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _pickAndRecognizeText(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

        setState(() {
          _controller.text = recognizedText.text;
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
      _steps = [];
    });
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.200:5000/solve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'problem': _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _solution = data['solution'] ?? '';
          _steps = List<String>.from(data['steps'] ?? []);
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
              ),
              maxLines: null,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickAndRecognizeText(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Scanner'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickAndRecognizeText(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Télécharger'),
                ),
              ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solution :',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(_solution),
                      if (_steps.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Explications :',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        ..._steps.map((step) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('- $step'),
                            )),
                      ],
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
