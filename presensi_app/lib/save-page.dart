import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
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
      // Cek jam saat ini sebelum menyimpan presensi
      if (!_isValidTime()) {
        _showAlert(
          "Presensi hanya dapat dilakukan 15 menit sebelum jam 07:00 dan setelah 14:30.",
        );
        return;
      }

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

  bool _isValidTime() {
    final now = DateTime.now();
    final before7AM = DateTime(now.year, now.month, now.day, 6, 45); // 06:45
    final at7AM = DateTime(now.year, now.month, now.day, 7, 0); // 07:00
    final after2PM = DateTime(now.year, now.month, now.day, 14, 30); // 14:30
    final at3PM = DateTime(now.year, now.month, now.day, 15, 0); // 15:00

    return (now.isAfter(before7AM) && now.isBefore(at7AM)) ||
        (now.isAfter(after2PM) && now.isBefore(at3PM));
  }

  void _showAlert(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Home"),
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
                          markerBuilder: (BuildContext context, int index) {
                            if (index == 0) {
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
                          initialMarkersCount: 2,
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
                    onPressed: () {
                      savePresensi(
                        currentLocation.latitude,
                        currentLocation.longitude,
                      );
                    },
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
