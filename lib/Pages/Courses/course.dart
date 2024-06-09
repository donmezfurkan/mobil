import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Courses/createExamPage.dart';
import 'package:scanitu/Pages/Courses/grade.dart';
import 'package:scanitu/utils/services/api_service.dart'; // Bu import'u eklemeyi unutmayın

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CoursePage(),
    );
  }
}

class CoursePage extends StatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  Map<String, List<Map<String, dynamic>>> courses = {};

  final VisionAPIService _visionAPIService = VisionAPIService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      List? fetchedCourses = await _visionAPIService.fetchCourses();
      Map<String, List<Map<String, dynamic>>> combinedData = {};

      // Tüm dersler için sınavları çek
      List<Future<List?>> examFutures = [];
      for (var course in fetchedCourses!) {
        String courseName = course['courseName'];
        combinedData[courseName] = [];
        examFutures.add(_visionAPIService.fetchExam(course['_id']));
      }
      print(examFutures);

      List? fetchedExamsList = await Future.wait(examFutures);

      // Gelen sınavları combinedData'ya ekle
      for (int i = 0; i < fetchedCourses.length; i++) {
        var courseName = fetchedCourses[i]['courseName'];
        var exams = fetchedExamsList[i];

        if (exams != null) {
          for (var exam in exams) {
            combinedData[courseName]?.add(exam);
          }
        }
      }

      setState(() {
        courses = combinedData;
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  void _addExam(String course, String exam, int questionCount) {
    setState(() {
      courses.update(course, (value) {
        value.add({'exam': exam, 'questionCount': questionCount});
        return value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Derslerim',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateExamPage(
                              courses: courses,
                              onAddExam: _addExam,
                            ),
                          ),
                        );
                      },
                      child: Text('Sınav Oluştur'),
                    ),
                  ),
                  SizedBox(width: 16), // Butonlar arasında boşluk bırakmak için
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnterGradePage(courses: courses),
                          ),
                        );
                      },
                      child: Text('Not Gir'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: courses.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: _buildCustomGrid(courses),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGrid(Map<String, List<Map<String, dynamic>>> courses) {
    List<Widget> gridItems = [];

    courses.forEach((courseName, exams) {
      gridItems.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        margin: const EdgeInsets.all(4.0),
        child: Column(
          
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                courseName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: exams.length > 4 ? 250 : exams.length * 25.0, // Sabit yükseklik veriyoruz
              child: SingleChildScrollView(
                child: Column(
                  children: exams.map((exam) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        exam['examName'] ?? 'N/A',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ));
    });

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.7,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: NeverScrollableScrollPhysics(),
      children: gridItems,
    );
  }
}
