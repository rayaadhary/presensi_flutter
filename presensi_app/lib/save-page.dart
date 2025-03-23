import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:presensi_app/models/save-presensi-response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as MyHttp;

class SavePage extends StatefulWidget {
  const SavePage({super.key});

  @override
  State<SavePage> createState() => _SavePageState();
}

class _SavePageState extends State<SavePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  static const double officeLatitude = -6.567956383451;
  static const double officeLongitude = 107.76280578344559;
  static const double radiusInMeters = 500;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Radius bumi dalam meter
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Jarak dalam meter
  }

  @override
  void initState() {
    super.initState();

    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('token') ?? "";
    });
  }

  Future<LocationData?> _currentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    Location location = new Location();

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  Future<void> savePresensi(latitude, longitude) async {
    try {
      Map<String, dynamic> body = {
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
      };

      String token = await _token;
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var response = await MyHttp.post(
        Uri.parse("http://10.0.2.2:8000/api/save-presensi"),
        body: json.encode(body),
        headers: headers,
      );

      if (response.body.isNotEmpty) {
        var responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          String message =
              responseData["message"] ?? "Terjadi kesalahan"; // Ambil message

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          // Jika sukses, tutup halaman
          if (responseData["success"] == true) {
            Navigator.pop(context);
          }
        } else {
          throw Exception("Format response tidak sesuai");
        }
      } else {
        throw Exception("Response kosong dari server");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: FutureBuilder<LocationData?>(
        future: _currentLocation(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final LocationData currentLocation = snapshot.data;

            // Hitung jarak ke kantor
            double distance = calculateDistance(
              currentLocation.latitude!,
              currentLocation.longitude!,
              officeLatitude,
              officeLongitude,
            );

            return SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 300,
                    child: SfMaps(
                      layers: [
                        MapTileLayer(
                          initialFocalLatLng: MapLatLng(
                            currentLocation.latitude!,
                            currentLocation.longitude!,
                          ),
                          initialZoomLevel: 15,
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          // Tambahkan dua marker
                          markerBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              // Marker untuk lokasi pengguna
                              return MapMarker(
                                latitude: currentLocation.latitude!,
                                longitude: currentLocation.longitude!,
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.red,
                                  size: 35,
                                ),
                              );
                            } else {
                              // Marker untuk lokasi kantor
                              return MapMarker(
                                latitude: officeLatitude,
                                longitude: officeLongitude,
                                child: Icon(
                                  Icons.business,
                                  color: Colors.blue,
                                  size: 35,
                                ),
                              );
                            }
                          },
                          initialMarkersCount: 2, // Pastikan jumlah marker = 2
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Minimal Jarak: ${radiusInMeters.toStringAsFixed(0)} meter",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Jarak ke kantor: ${distance.toStringAsFixed(0)} meter",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    child: Text("Save"),
                    onPressed:
                        distance <= radiusInMeters
                            ? () {
                              savePresensi(
                                currentLocation.latitude,
                                currentLocation.longitude,
                              );
                            }
                            : null, // Disabled jika jarak lebih dari radius
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
