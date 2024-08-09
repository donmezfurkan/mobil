import 'package:scanitu/Pages/Courses/course.dart' as course;
import 'package:scanitu/Pages/HomePage/home.dart';
import 'package:scanitu/Pages/Login/login.dart';
import 'package:scanitu/Pages/Settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:scanitu/Pages/Profile/profile.dart' as profile;

import 'package:shared_preferences/shared_preferences.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('AnaSayfa'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage(userName: '', courses: {},)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const profile.ProfilePage(userName: '', userImage: '',)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Sınıflarım'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const course.CoursePage(course: {},)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: ()=> _logout(context) 
            // {
            //  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
            // },
          ),
        ],
      ),
    );
  }
}

class CameraIconWidget extends StatelessWidget {
  final void Function(File?) onImageSelected;

  const CameraIconWidget({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final ImagePicker _picker = ImagePicker();
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          onImageSelected(File(image.path));
        }
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.camera_alt),
    );
  }
}
