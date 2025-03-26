import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presensi_app/components/navigation.dart';
import 'package:presensi_app/models/home-response.dart';
import 'package:presensi_app/save-page.dart';
import 'package:presensi_app/login-page.dart';
import 'package:presensi_app/history-presensi-page.dart'; // Import halaman Riwayat Presensi
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:presensi_app/services/notification-service.dart';

import 'package:http/http.dart' as MyHttp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late Future<String> _token, _name;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then(
      (SharedPreferences prefs) => prefs.getString("token") ?? "",
    );
    _name = _prefs.then(
      (SharedPreferences prefs) => prefs.getString("name") ?? "",
    );

    _initNotifications();
    _requestNotificationPermission();
    NotificationService.init();
    NotificationService.scheduleDailyReminders();
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> getData() async {
    final Map<String, String> headers = {
      'Authorization': 'Bearer ' + await _token,
    };
    var response = await MyHttp.get(
      Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
      headers: headers,
    );

    // print("Response Code: ${response.body}");


    homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
    riwayat.clear();
    homeResponseModel!.data.forEach((element) {
      if (element.isHariIni) {
        hariIni = element;
      } else {
        riwayat.add(element);
      }
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification() async {
    print("Mau tampilkan notifikasi...");
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      'Halo!', // Judul notifikasi
      'Ini notifikasi pertama lo di Flutter', // Isi notifikasi
      notificationDetails,
    );
    print("Notifikasi sudah dikirim!");
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await _prefs;
    String? token = prefs.getString("token");
    if (token != null && token.isNotEmpty) {
      var response = await MyHttp.post(
        Uri.parse("http://10.0.2.2:8000/api/logout"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        setState(() {});
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal logout, coba lagi")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return _selectedIndex == 0
                ? buildHomeScreen()
                : _selectedIndex == 1
                ? SavePage()
                : HistoryPresensiPage(riwayat: riwayat);
          }
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget buildHomeScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _name,
              builder: (context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else {
                  return Text(
                    'Halo, ${snapshot.data ?? "-"}',
                    style: TextStyle(fontSize: 18),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      hariIni?.tanggal ?? '-',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              hariIni?.masuk ?? '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              "MASUK",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              hariIni?.pulang ?? '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              "PULANG",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showNotification,
              child: Text('Tampilkan Notifikasi'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
