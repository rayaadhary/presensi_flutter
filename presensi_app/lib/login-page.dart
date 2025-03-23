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
    if (tokenStr != "" && nameStr != "") {
      Future.delayed(Duration(seconds: 1), () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => HomePage()))
            .then((value) {
              setState(() {});
            });
      });
    }
  }

  Future login(email, password) async {
    LoginResponseModel? loginResponseModel;

    Map<String, String> body = {"email": email, "password": password};

    // final headers = {
    //   'Content-Type' : 'application/json',
    // };

    var response = await MyHttp.post(
      Uri.parse("http://10.0.2.2:8000/api/login"),
      body: json.encode(body),
    );

    if (response.statusCode == 401) {
    } else {
      loginResponseModel = LoginResponseModel.fromJson(
        json.decode(response.body),
      );
      saveUser(loginResponseModel.data.token, loginResponseModel.data.name);
      // print("HASIL: ${response.body}");
    }
  }

  Future saveUser(token, name) async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Email atau Password Salah!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Text('LOGIN')),
                SizedBox(height: 20),
                Text('EMAIL'),
                TextField(controller: emailController),
                SizedBox(height: 20),
                Text('PASSWORD'),
                TextField(controller: passwordController, obscureText: true),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      login(emailController.text, passwordController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('MASUK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
