import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presensi_app/home-page.dart';
import 'package:http/http.dart' as MyHttp;
import 'package:presensi_app/models/login-response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  late Future<String> _token, _name;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('token') ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('name') ?? "";
    });

    checkToken(_token, _name);
  }

  checkToken(token, name) async {
    String tokenStr = await token;
    String nameStr = await name;

    if (tokenStr.isNotEmpty && nameStr.isNotEmpty) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

  Future login(String email, String password) async {
    try {
      Map<String, String> body = {"email": email, "password": password};

      var response = await MyHttp.post(
        Uri.parse("http://10.0.2.2:8000/api/login"),
        body: body,
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Jika login berhasil
        LoginResponseModel loginResponseModel = LoginResponseModel.fromJson(
          json.decode(response.body),
        );

        await saveUser(
          loginResponseModel.data.token,
          loginResponseModel.data.name,
        );
      } else if (response.statusCode == 401) {
        // Jika email atau password salah
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Email atau Password Salah!")));
      } else {
        // Jika terjadi kesalahan lain
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan, coba lagi!")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan jaringan!")));
    }
  }

  Future saveUser(String token, String name) async {
    try {
      final SharedPreferences prefs = await _prefs;
      prefs.setString("name", name);
      prefs.setString("token", token);

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => HomePage())).then((value) {
        setState(() {});
      });
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan saat menyimpan data!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(height: 30), // Jarak atas biar tidak terlalu mepet
                Center(
                  child: Image.asset('assets/images/logo_rs.png', width: 150),
                ),
                SizedBox(height: 20),

                // Form Login dalam Container agar tidak kepanjangan
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 250,
                  ), // Batasi lebar maksimum
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email TextField
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan email',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ), // Placeholder lebih redup
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Border lebih halus
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Password TextField
                      TextField(
                        controller: passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ), // Placeholder lebih redup
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Border lebih halus
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Tombol Login (Lebar Sama dengan TextField)
                      SizedBox(
                        width: double.infinity, // Lebarkan tombol
                        child: ElevatedButton(
                          onPressed: () {
                            login(
                              emailController.text,
                              passwordController.text,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  14, // Tambah tinggi tombol agar proporsional
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Sesuai border textfield
                            ),
                          ),
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40), // Jarak bawah agar tidak terlalu mepet
              ],
            ),
          ),
        ),
      ),
    );
  }
}
