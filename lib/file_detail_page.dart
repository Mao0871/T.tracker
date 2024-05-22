import 'dart:io';
import 'package:flutter/material.dart';

class FileDetailPage extends StatelessWidget {
  final String filePath;

  const FileDetailPage({super.key, required this.filePath});

  Future<String> _readFileContent() async {
    final file = File(filePath);
    return await file.readAsString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filePath.split('/').last),
      ),
      body: FutureBuilder<String>(
        future: _readFileContent(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error loading file content');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('File is empty');
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(snapshot.data!),
            );
          }
        },
      ),
    );
  }
}
