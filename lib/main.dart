import 'package:flutter/material.dart';
import 'package:scanitu/Pages/HomePage/home.dart';
import 'package:scanitu/Pages/Courses/course.dart';
import 'package:scanitu/Pages/Profile/profile.dart';
import 'package:scanitu/Pages/Settings/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Main Screen Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white, // Ensure the background color is white
          selectedItemColor: Color.fromARGB(255, 4, 4, 67), // Seçili buton rengi
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(
      userName: '',
      courses: {},
    ),
    const ProfilePage(userName: '', userImage: ''),
    const CoursePage(
      course: {},
    ),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
    );
  }
}
