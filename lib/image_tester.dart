import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Storage',
      home: UploadFilePage(),
    );
  }
}

class UploadFilePage extends StatefulWidget {
  @override
  _UploadFilePageState createState() => _UploadFilePageState();
}

class _UploadFilePageState extends State<UploadFilePage> {
  File? _file;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) return;

    try {
      final fileName = _file!.path.split('/').last;
      final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');
      final uploadTask = storageRef.putFile(_file!);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded successfully. Download URL: $downloadUrl');
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File to Firebase Storage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Pick File'),
            ),
            if (_file != null) ...[
              Text('Selected File: ${_file!.path.split('/').last}'),
              ElevatedButton(
                onPressed: _uploadFile,
                child: Text('Upload File'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
