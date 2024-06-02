import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Profile/profile.dart' as profile;
import 'package:scanitu/Pages/Courses/course.dart' as course;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Örnek kullanıcı bilgileri
    final String userName = "John Doe";
    final String userImage = "assets/images/profile_image.jpg";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Ana Sayfa',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                // Navigate to profile page with user data
                Navigator.push(context, MaterialPageRoute(builder: (context) => profile.ProfilePage(userName: userName, userImage: userImage)));
              },
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(20.0),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/profile_image.jpg'),
                      radius: 30,
                    ),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba,',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Kullanıcı Adı Soyadı',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('course'),
                  onTap: () {
                    // Navigate to course details page
                    Navigator.push(context, MaterialPageRoute(builder: (context) => course.CoursePage()));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
