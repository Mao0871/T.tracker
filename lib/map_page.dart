import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  final List<LatLng> locations;

  const MapPage({super.key, required this.locations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: locations.isNotEmpty ? locations[0] : LatLng(0, 0),
          zoom: 10,
        ),
        markers: locations.map((location) => Marker(
          markerId: MarkerId(location.toString()),
          position: location,
        )).toSet(),
      ),
    );
  }
}
