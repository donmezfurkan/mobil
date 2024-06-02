import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanitu/Pages/Login/login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil Bilgilerini Güncelle'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Profil güncelleme sayfasına yönlendirme kodu buraya gelecek
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Dil Seçimi'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Dil seçimi sayfasına yönlendirme kodu buraya gelecek
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Gizlilik ve Güvenlik'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Gizlilik ve güvenlik sayfasına yönlendirme kodu buraya gelecek
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Hakkında'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Hakkında sayfasına yönlendirme kodu buraya gelecek
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Çıkış Yap'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
