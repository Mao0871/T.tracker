import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'file_list_page.dart';
import 'file_detail_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T.tracker BEAT V0.2.3.4.2',
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

//页面跳转代码实现
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    MyHomePage(title: 'GPS Tracker'),//主页面
    FileListPage(),//文件记录界面
  ];
//定义了一个list用于返回对应的界面
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T.tracker BEAT V0.2.3.4.2'),//通知栏的字符串
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(//顶部导航栏，现在使用username作为占位
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
                _onItemTapped(0);//调用界面1，也就是主界面
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
  String _satelliteStatus = "Unknown"; // Initial unknown status
  bool _isTracking = false;
  Timer? _timer;
  static const platform = MethodChannel('com.example.gps/record');//和原生安卓通讯

  double? _lastLatitude;
  double? _lastLongitude;
  double? _lastAccuracy;
  int? _lastSatellites;

  @override
  void initState() {
    super.initState();
    //_checkPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        _lastAccuracy = position.accuracy;
        _locationMessage = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _updateSatelliteStatus(position.accuracy);
      });

      await platform.invokeMethod('recordLocation', {//与安卓通讯，使用MainActivity中的recordLocatio方法
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Failed to get location: ${e.toString()}");
    }
  }

  void _updateSatelliteStatus(double? accuracy) {
    if (accuracy == null) {
      _satelliteStatus = "Unknown";
      return;
    }
    if (accuracy <= 5) {
      _satelliteStatus = "Good";
    } else if (accuracy <= 9) {
      _satelliteStatus = "Ok";
    } else if (accuracy <= 14) {
      _satelliteStatus = "Not Bad";
    } else {
      _satelliteStatus = "Bad";
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
    _getCurrentLocation();
    _timer = Timer.periodic(Duration(milliseconds: 1000), (Timer t) => _getCurrentLocation());
  }

  void _stopTracking() {
    _timer?.cancel();
    setState(() {
      _isTracking = false;
    });
    String endTime = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '');
    platform.invokeMethod('saveFile', {'endTime': endTime}).catchError((e) {//与安卓通讯，使用MainActivity中的saveFile方法
      print("Failed to save file: '${e.message}'");
    });
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(_locationMessage, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _toggleTracking, child: Text(_isTracking ? "Stop" : "Start")),
        const SizedBox(height: 20),
        Text("Satellite Status: $_satelliteStatus", style: Theme.of(context).textTheme.subtitle1),
        if (_lastAccuracy != null) Text("Accuracy: ${_lastAccuracy}m", style: Theme.of(context).textTheme.subtitle1),
      ],
    );
  }
}

