import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Profile/profile.dart' as profile;
import 'package:scanitu/Pages/Courses/course.dart';
import 'package:scanitu/utils/services/api_service.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String userImage;
  final Map<String, List<Map<String, dynamic>>> courses;

  const HomePage({
    super.key,
    required this.userName,
    required this.userImage,
    required this.courses, String? userToken,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  Map<String, dynamic> _userProfile = {};
  List<dynamic>? fetchedCourses;

  @override
  void initState() {
    super.initState();
    fetchUserProfileData();
    _loadCoursesFromAPI();
  }

  Future<void> fetchUserProfileData() async {
    final userProfile = await _visionAPIService.fetchUserProfile();
    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile['userProfile'];
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri alınırken bir hata oluştu')),
      );
    }
  }

  Future<void> _loadCoursesFromAPI() async {
    final courses = await _visionAPIService.fetchCourses();
    setState(() {
      fetchedCourses = courses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _userProfile['firstLastName'] ?? widget.userName;
    final String userImage = _userProfile['userImage'] ?? widget.userImage;

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => profile.ProfilePage(
                      userName: userName,
                      userImage: userImage,
                    ),
                  ),
                );
              },
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      //backgroundImage: AssetImage(userImage),
                      radius: 30,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Merhaba,',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Boşluk eklemek için SizedBox kullanımı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'DERSLERİM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: fetchedCourses == null
                ? const Center(child: CircularProgressIndicator())
                : fetchedCourses!.isEmpty
                    ? const Center(child: Text('Henüz kurs bulunmamaktadır.'))
                    : ListView.builder(
                        itemCount: fetchedCourses!.length,
                        itemBuilder: (context, index) {
                          final course = fetchedCourses![index];
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(course['courseCode'].toString()), // Ensure it's a String
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Text(course['courseName'] ?? 'Ders İsmi Yok'),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoursePage(),
                                ),
                              );
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
