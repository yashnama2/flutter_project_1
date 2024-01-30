import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  MapScreen({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('OpenStreetMap'),
      // ),
      body: FlutterMap(
        
        options: MapOptions(
          initialCenter: LatLng(latitude!, longitude!),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 30.0,
                height: 30.0,
                point: LatLng(latitude!, longitude!),
                child: Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 40,)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
