import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scanitu/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    Map<String, dynamic> loginData = {
      "userName": username,
      "password": password,
    };
    bool error = false;
    String message = "";

    try {
      final response = await http.post(
        //Uri.parse('http://169.254.241.104:3030/api/auth/login'),
        //Uri.parse('http://169.254.40.200:3030/api/auth/login'),
        Uri.parse('http://localhost:3030/api/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginData),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        Map<String, dynamic> payload = Jwt.parseJwt(token);
        String userId = payload['id'];

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userToken", jsonDecode(response.body)["token"]);
        await prefs.setString("userName", username);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString(
            'userId', userId); // Kullanıcının giriş yaptığını kaydet

        print('Login successful. Token: ${response.body}');
        message = 'Login successful. Token: ${response.body}';
        error = false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      } else {
        print('Login failed. Error: ${response.body}');
        message = 'Login failed. Error: ${response.body}';
        error = true;

        _showErrorDialog(message);
      }
    } catch (e) {
      print('Error during login: $e');
      message = 'Error during login: $e';
      error = true;

      _showErrorDialog(message);
    }
  }

  void _launchURL() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SamlLoginPage()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color.fromARGB(255, 134, 191, 249)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, right: 64.0, left: 64.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'SCANITU',
                    style: TextStyle(
                      fontSize: 42.0, // Set the font size
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 44, 44, 117), // Set the color to blue
                    ),
                  ),
                  const SizedBox(height: 60.0),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_circle),
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                      hoverColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 64.0),
                  ElevatedButton(
                    onPressed: _login,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 4, 4, 67)),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _launchURL,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    child: const Text(
                      'İTÜ Giriş',
                      style: TextStyle(
                        color: Color.fromARGB(255, 4, 4, 67),
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SamlLoginPage extends StatefulWidget {
  @override
  _SamlLoginPageState createState() => _SamlLoginPageState();
}

class _SamlLoginPageState extends State<SamlLoginPage> {
  @override
  void initState() {
    super.initState();
    // Sadece Android için gerekli olabilir
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SAML Login'),
      ),
      body: WebView(
        initialUrl: 'https://girisv3.itu.edu.tr/saml/login.aspx',
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (String url) {
          if (url.contains('/login/callback')) {
            // Kullanıcı başarıyla kimlik doğrulandı
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
