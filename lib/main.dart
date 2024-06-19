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
      title: 'T.tracker BEAT V0.2.3.3',
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
        title: const Text('T.tracker BEAT V0.2.3.3'),
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
  String _satelliteStatus = "Unknown"; // 初始状态为未知
  bool _isTracking = false;
  Timer? _timer;
  static const platform = MethodChannel('com.example.gps/record');

  double? _lastLatitude;
  double? _lastLongitude;
  double? _lastAccuracy;
  int? _lastSatellites;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getCurrentLocation();  // 启动位置监听
  }


  Future<void> _checkPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Permission is granted
    } else if (status.isDenied) {
      // Permission is denied, request again
      await Permission.location.request();
    } else if (status.isPermanentlyDenied) {
      // Permissions are permanently denied, we cannot request permissions.
      openAppSettings();
    }
  }



  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查定位服务是否启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 未启用定位服务
      return;
    }

    // 检查定位权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 用户拒绝权限
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 权限永久拒绝，无法请求
      return;
    }

    // 获取位置流并监听更新
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream().listen(
            (Position position) {
          if (position != null) {
            double latitude = position.latitude;
            double longitude = position.longitude;
            double? accuracy = position.accuracy;

            // 在此更新状态
            setState(() {
              _lastLatitude = latitude;
              _lastLongitude = longitude;
              _lastAccuracy = accuracy;
              _locationMessage = "Latitude: $latitude, Longitude: $longitude";
              // 使用位置精度更新卫星状态
              if (accuracy != null) {
                if (accuracy <= 5) {
                  _satelliteStatus = "Good";
                } else if (accuracy <= 9) {
                  _satelliteStatus = "Ok";
                } else if (accuracy <= 14){
                  _satelliteStatus = "Not Bad";
                }else{
                  _satelliteStatus = "Bad";
                }
              } else {
                _satelliteStatus = "Unknown";
              }
            });
          }
        });
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();  // 确保不会创建多个计时器
    }
    DateTime? lastTime;
    _timer = Timer.periodic(Duration(milliseconds: 30), (Timer t) {
      DateTime now = DateTime.now();
      if (lastTime != null) {
        Duration actualInterval = now.difference(lastTime!);
        print("Actual interval: ${actualInterval.inMilliseconds} ms");
      }
      lastTime = now;
      // 这里可以添加其他需要周期执行的代码
    });
  }


  void _stopTracking() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    setState(() {
      _isTracking = false;
    });
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

  // 主页面最终显示的布局和内容
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
        const SizedBox(height: 20),
        Text(
          "Satellite Status: $_satelliteStatus",
          style: Theme.of(context).textTheme.subtitle1,
        ),
        if (_lastAccuracy != null) // 仅当有精度信息时显示
          Text(
            "Accuracy: ${_lastAccuracy}m",
            style: Theme.of(context).textTheme.subtitle1,
          ),
      ],
    );
  }
}
