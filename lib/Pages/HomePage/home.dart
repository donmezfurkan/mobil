import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Courses/course.dart';
import 'package:scanitu/Pages/Courses/courseSingle.dart';
import 'package:scanitu/Pages/Profile/profile.dart' as profile;
import 'package:scanitu/utils/services/api_service.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final Map<String, List<Map<String, dynamic>>> courses;

  const HomePage({
    super.key,
    required this.userName,
    required this.courses,
    String? userToken,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();

  Map<String, dynamic> _userProfile = {};
  List<dynamic>? fetchedCourses;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUserProfileData();
    _loadCoursesFromAPI();
    _startAutoSlide();
  }

  Future<void> fetchUserProfileData() async {
    final userProfile = await _visionAPIService.fetchUserProfile();
    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile['userProfile'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgileri alınırken bir hata oluştu'),
        ),
      );
    }
  }

  Future<void> _loadCoursesFromAPI() async {
    final courses = await _visionAPIService.fetchCourses();
    setState(() {
      fetchedCourses = courses;
    });
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        int nextPage = _currentPage < 2 ? _currentPage + 1 : 0;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );

        setState(() {
          _currentPage = nextPage;
        });

        _startAutoSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _userProfile['firstLastName'] ?? widget.userName;
    final String userImage = _userProfile['userImage'] ?? "images/itu.jpeg";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Ana Sayfa',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
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
                padding: const EdgeInsets.all(50.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(userImage),
                      radius: 30.0,
                    ),
                    const SizedBox(width: 30.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Merhaba,',
                          style: TextStyle(fontSize: 18.0),
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
            const SizedBox(height: 20.0),

            // Slayt gösterimi
            SizedBox(
              height: 200.0,
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildSlide(
                        "Uygulamanızı keşfedin",
                        "İhtiyacınız olan her şey burada!",
                        [Colors.blue, Colors.purple],
                      ),
                      _buildSlide(
                        "Derslerinizi kolayca yönetin",
                        "Tüm derslerinizi tek bir yerden yönetin.",
                        [Colors.green, Colors.teal],
                      ),
                      _buildSlide(
                        "Sınavlarınız hızlıca kaydedin",
                        "Notları kolayca dijitalleştirin!",
                        [Colors.orange, Colors.red],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10.0,
                    left: 0.0,
                    right: 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(3, (int index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          height: 8.0,
                          width: _currentPage == index ? 16.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.blue
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoursePage(course: {}),
                    ),
                  );
                  if (result == true) {
                    _loadCoursesFromAPI();
                  }
                },
                child: const Row(
                  children: [
                    Text(
                      'DERSLERİM',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    //Spacer(),
                    SizedBox(width: 16),  // This pushes the icon to the right
                    Icon(Icons.arrow_forward, size: 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 300, // Set a fixed height for the course list
              child: fetchedCourses == null
                  ? const Center(child: CircularProgressIndicator())
                  : fetchedCourses!.isEmpty
                      ? const Center(child: Text('Henüz kurs bulunmamaktadır.'))
                      : ListView.builder(
                          itemCount: fetchedCourses!.length,
                          itemBuilder: (context, index) {
                            final course = fetchedCourses![index];
                            return Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CourseSinglePage(course: course),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                              course['courseCode'].toString()),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child: Text(course['courseName'] ??
                                              'Ders İsmi Yok'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(), // This adds a line under each ListTile
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(String title, String subtitle, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 6.0,
                    color: Colors.black54,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.white70,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black54,
                    offset: Offset(2.0, 2.0),
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
