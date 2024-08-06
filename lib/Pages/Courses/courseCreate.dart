import 'package:flutter/material.dart';
import 'package:scanitu/utils/services/api_service.dart';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseCrnController = TextEditingController();

  Future<void> _addCourse() async {
    if (_courseNameController.text.isEmpty ||
        _courseCodeController.text.isEmpty ||
        _courseCrnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final newCourse = await _visionAPIService.createCourse(
      _courseCodeController.text,
      _courseNameController.text,
      _courseCrnController.text,
    );

    if (newCourse != null) {
      _courseNameController.clear();
      _courseCodeController.clear();
      _courseCrnController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders başarıyla eklendi')),
      );

      Navigator.pop(context, true); // Return to the previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders eklenirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Yeni Ders Kayıt',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Ders Kodu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Ders Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _courseCrnController,
              decoration: const InputDecoration(
                labelText: 'Ders CRN\'si',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCourse,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 4, 4, 67)),
              ),
              child: const Text(
                'Ders Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
