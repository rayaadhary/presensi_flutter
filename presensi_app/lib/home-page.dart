import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presensi_app/models/home-response.dart';
import 'package:presensi_app/save-page.dart';
import 'package:presensi_app/login-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as MyHttp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token, _name;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });

  }

  Future getData() async {
    final Map<String, String> headers = {
      'Authorization': 'Bearer ' + await _token,
    };

    var response = await MyHttp.get(
      Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
      headers: headers,
    );

    homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
    riwayat.clear();
    homeResponseModel!.data.forEach((element) {
      if (element.isHariIni) {
        hariIni = element;
      } else {
        riwayat.add(element);
      }
    });

    print('DATA: ' + response.body);
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

      print(response.body);

      if (response.statusCode == 200) {
        // Hapus token & pastikan UI diperbarui
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
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder(
                      future: _name,
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else {
                          if (snapshot.hasData) {
                            return Text(
                              'Halo, ${snapshot.data}',
                              style: TextStyle(fontSize: 18),
                            );
                          } else {
                            return Text("-", style: TextStyle(fontSize: 18));
                          }
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 400,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          child: Text("Logout"),
                          onPressed: () {
                            logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("Riwayat Presensi"),
                    Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder:
                            (context, index) => Card(
                              child: ListTile(
                                leading: Text(
                                  riwayat[index].tanggal.isNotEmpty
                                      ? riwayat[index].tanggal
                                      : '-',
                                  style: TextStyle(fontSize: 9),
                                ),
                                title: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          riwayat[index].masuk.isNotEmpty
                                              ? riwayat[index].masuk
                                              : '-',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          "MASUK",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 20),
                                    Column(
                                      children: [
                                        Text(
                                          riwayat[index].pulang.isNotEmpty
                                              ? riwayat[index].pulang
                                              : '-',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          "PULANG",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => SavePage()))
              .then((value) {
                setState(() {});
              });
        },
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
