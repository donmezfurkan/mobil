import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Courses/courseCreate.dart';
import 'package:scanitu/Pages/Courses/courseEdit.dart';
import 'package:scanitu/utils/services/api_service.dart';

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
      home: const CoursePage(
        course: {},
      ),
    );
  }
}

class CoursePage extends StatefulWidget {
  final Map<String, dynamic> course;
  const CoursePage({Key? key, required this.course}) : super(key: key);
  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  Map<String, List<Map<String, dynamic>>> courses = {};
  final VisionAPIService _visionAPIService = VisionAPIService();
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      List<dynamic>? fetchedCourses = await _visionAPIService.fetchCourses();
      if (fetchedCourses == null || fetchedCourses.isEmpty) {
        setState(() {
          courses = {};
          _selectedCourseId = null;
        });
        return;
      }

      Map<String, List<Map<String, dynamic>>> combinedData = {};

      // Fetch exams for all courses
      List<Future<List?>> examFutures = [];
      for (var course in fetchedCourses) {
        String courseId = course['_id'];
        String courseName = course['courseName'];
        combinedData[courseId] = [{'courseName': courseName}];
        examFutures.add(_visionAPIService.fetchExam(courseId));
      }

      List<dynamic>? fetchedExamsList = await Future.wait(examFutures);

      // Add fetched exams to combinedData
      for (int i = 0; i < fetchedCourses.length; i++) {
        var courseId = fetchedCourses[i]['_id'];
        var exams = fetchedExamsList[i];

        if (exams != null) {
          for (var exam in exams) {
            exam['courseId'] = courseId;
            combinedData[courseId]?.add(exam);
          }
        }
      }

      setState(() {
        courses = combinedData;
        if (courses.isNotEmpty) {
          _selectedCourseId = courses.keys.first;
        } else {
          _selectedCourseId = null;
        }
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    if (courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen silmek için bir ders seçin')),
      );
      return;
    }

    final Map<String, dynamic>? success = await _visionAPIService.deleteCourse(courseId);

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders başarıyla silindi')),
      );
      await _fetchData(); // Refresh the data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders silinirken bir hata oluştu')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? dialogSelectedCourseId = _selectedCourseId;
        return AlertDialog(
          title: const Text('Ders Sil'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Silmek istediğiniz dersi seçin:'),
                  const SizedBox(height: 16.0),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: dialogSelectedCourseId,
                    hint: const Text('Ders Seçin'),
                    onChanged: (String? newValue) {
                      setState(() {
                        dialogSelectedCourseId = newValue;
                      });
                    },
                    items: courses.entries.map((entry) {
                      String courseId = entry.key;
                      String courseName = entry.value.isNotEmpty && entry.value.first.containsKey('courseName')
                          ? entry.value.first['courseName']
                          : 'Unknown Course';
                      return DropdownMenuItem<String>(
                        value: courseId,
                        child: Text(courseName),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (dialogSelectedCourseId != null) {
                  Navigator.of(context).pop();
                  _deleteCourse(dialogSelectedCourseId!);
                }
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCourseActionCompleted() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Derslerim',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context, true); // Pop with a true result
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                children: [
                  _buildGridItem(
                    context,
                    'Ders Oluştur',
                    Icons.add,
                    () async {
                      bool? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateCoursePage(),
                        ),
                      );
                      if (result == true) {
                        _onCourseActionCompleted();
                      }
                    },
                  ),
                  _buildGridItem(
                    context,
                    'Ders Düzenle',
                    Icons.edit,
                    () async {
                      bool? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditCoursePage(course: {}),
                        ),
                      );
                      if (result == true) {
                        _onCourseActionCompleted();
                      }
                    },
                  ),
                  _buildGridItem(
                    context,
                    'Ders Sil',
                    Icons.delete,
                    courses.isEmpty ? null : _showDeleteConfirmationDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 4, 4, 67),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Colors.white),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
