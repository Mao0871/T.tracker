import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_page.dart';  // 新增

class FileDetailPage extends StatelessWidget {
  final String filePath;

  const FileDetailPage({super.key, required this.filePath});

  Future<List<LatLng>> _readFileContent() async {
    final file = File(filePath);
    final content = await file.readAsString();
    final lines = content.split('\n');
    final List<LatLng> locations = [];

    for (var line in lines) {
      if (line.isNotEmpty) {
        final json = jsonDecode(line);
        final latitude = json['latitude'];
        final longitude = json['longitude'];
        locations.add(LatLng(latitude, longitude));
      }
    }
    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filePath.split('/').last),
      ),
      body: FutureBuilder<List<LatLng>>(
        future: _readFileContent(),
        builder: (BuildContext context, AsyncSnapshot<List<LatLng>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error loading file content');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('File is empty');
          } else {
            final locations = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Total Locations: ${locations.length}'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(locations: locations),
                        ),
                      );
                    },
                    child: Text('Show on Map'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
