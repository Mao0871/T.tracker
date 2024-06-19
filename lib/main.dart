import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'file_list_page.dart';
import 'file_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T.tracker BEAT V0.2.3.2',
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
        title: const Text('T.tracker BEAT V0.2.3.2'),
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
                'User Name',
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
    DateTime? lastTime;
    _getCurrentLocation(); // 立即获取当前位置
    _timer = Timer.periodic(Duration(milliseconds: 50), (Timer t) {//20毫秒
      DateTime now = DateTime.now();
      if (lastTime != null) {
        Duration actualInterval = now.difference(lastTime!);
        print("Actual interval: ${actualInterval.inMilliseconds} ms");//打印在控制台看实际延迟
      }
      lastTime = now;
      _getCurrentLocation(); // 获取当前位置，在定时器的周期内
    });
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
