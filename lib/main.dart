import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'file_list_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T.tracker BEAT V0.2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    MyHomePage(title: 'GPS Tracker'),
    FileListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T.tracker BEAT V0.2.1'),
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('GPS Tracker'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Recorded Files'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _locationMessage = "Press the button to get location";
  bool _isTracking = false;
  Timer? _timer;
  static const platform = MethodChannel('com.example.gps/record');

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationMessage =
      "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });

    try {
      await platform.invokeMethod('recordLocation', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on PlatformException catch (e) {
      print("Failed to record location: '${e.message}'.");
    }
  }

  void _startTracking() {
    _getCurrentLocation();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _getCurrentLocation());
  }

  void _stopTracking() {
    _timer?.cancel();
    String endTime = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '');
    try {
      platform.invokeMethod('saveFile', {
        'endTime': endTime,
      });
    } on PlatformException catch (e) {
      print("Failed to save file: '${e.message}'.");
    }
  }

  void _toggleTracking() {
    setState(() {
      if (_isTracking) {
        _stopTracking();
        _isTracking = false;
      } else {
        _startTracking();
        _isTracking = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _locationMessage,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _toggleTracking,
          child: Text(_isTracking ? "Stop" : "Start"),
        ),
      ],
    );
  }
}

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  Future<List<String>> _getRecordedFiles() async {
    final directory = await getExternalStorageDirectory();
    final files = directory!.listSync();
    return files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.path.split('/').last)
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
                title: Text(snapshot.data![index]),
              );
            },
          );
        }
      },
    );
  }
}
