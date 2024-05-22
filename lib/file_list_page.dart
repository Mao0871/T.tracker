import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'file_detail_page.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  Future<List<String>> _getRecordedFiles() async {
    final directory = await getExternalStorageDirectory();
    final files = directory!.listSync();
    return files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.path)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getRecordedFiles(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error loading files');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No files recorded');
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index].split('/').last),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileDetailPage(
                        filePath: snapshot.data![index],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
