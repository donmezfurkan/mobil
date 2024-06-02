import 'package:flutter/material.dart';
import 'package:scanitu/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        Uri.parse('http://172.20.10.2:3030/api/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginData),
      );
      print(loginData);
      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userToken", jsonDecode(response.body)["token"]);
        await prefs.setString("userName", username);
        await prefs.setBool('isLoggedIn', true); // Kullanıcının giriş yaptığını kaydet

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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0, right: 64.0, left: 64.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo_inline.png',
                  height: 60,
                ),
                const SizedBox(height: 60.0),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_circle),
                    border: OutlineInputBorder(),
                    labelText: 'Username',
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
                FilledButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
