import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scanitu/utils/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateExamPage extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> courses;
  //final Function(String, String, int) onAddExam;

  const CreateExamPage({Key? key, required this.courses, required void Function(String course, String exam, int questionCount) onAddExam}) : super(key: key);

  @override
  _CreateExamPageState createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  String? selectedCourseId;
  String? examName;
  int? questionCount;
  List<dynamic>? fetchedCourses;
  final VisionAPIService _visionAPIService = VisionAPIService();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCoursesFromAPI();
  }

  Future<String?> getUserToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("userToken");
}

  Future<void> _loadCoursesFromAPI() async {
    List<dynamic>? courses = (await _visionAPIService.fetchCourses()) as List?;
    setState(() {
      fetchedCourses = courses;
    });
  }

  Future<void> _createExam() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCourseId != null && examName != null && questionCount != null) {
        //await widget.onAddExam(selectedCourseId!, examName!, questionCount!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sınav başarıyla oluşturuldu!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createExamRequest(String selectedCourseId, String examName, int questionCount) async {
    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }
    final response = await http.post(
      Uri.parse('http://localhost:3030/api/exam/exam-create'),
      //Uri.parse('http://169.254.123.91:3030/api/exam/exam-create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "token": userToken,
      },
      body: jsonEncode(<String, dynamic>{
        'courseId': selectedCourseId,
        'examName': examName,
        'questionNumber': questionCount,
      }),
    );
    if (response.statusCode == 200) {
      // Sınav başarıyla oluşturuldu
      print('Exam created successfully');
    } else {
      // Hata oluştu
      throw Exception('Failed to create exam');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Oluştur'),
      ),
      body: fetchedCourses == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Ders Seçin'),
                      value: selectedCourseId,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCourseId = newValue;
                        });
                      },
                      items: fetchedCourses!.map((dynamic course) {
                        return DropdownMenuItem<String>(
                          value: course['_id'],
                          child: Text(course['courseName']),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen bir ders seçin';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Sınav Adı'),
                      onChanged: (value) {
                        setState(() {
                          examName = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen sınav adını girin';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Soru Sayısı'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          questionCount = int.tryParse(value);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen soru sayısını girin';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir sayı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _createExam();
                        if (selectedCourseId != null && examName != null && questionCount != null) {
                          await _createExamRequest(selectedCourseId!, examName!, questionCount!);
                        }
                      },
                      child: const Text('Sınav Oluştur'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
