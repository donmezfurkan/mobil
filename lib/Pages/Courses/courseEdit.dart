import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:scanitu/utils/services/api_service.dart';
import 'package:http/http.dart' as http;

class EditCoursePage extends StatefulWidget {
  final Map<String, dynamic> course;

  const EditCoursePage({Key? key, required this.course}) : super(key: key);

  @override
  _EditCoursePageState createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseCrnController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic>? _selectedCourse;
  File? _selectedFile;
  List<List<dynamic>> _excelData = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _populateFields(widget.course);
  }

  Future<void> _loadCourses() async {
    final courses = await _visionAPIService.fetchCourses();
    setState(() {
      _courses = (courses as List<dynamic>).cast<Map<String, dynamic>>();
      if (_courses.isNotEmpty) {
        _selectedCourse = _courses.first;
        _populateFields(_selectedCourse!);
      }
    });
  }

  void _populateFields(Map<String, dynamic> course) {
    _courseNameController.text = course['courseName'] ?? '';
    _courseCodeController.text = course['courseCode'] ?? '';
    _courseCrnController.text = course['courseCRN'].toString() ?? '';
  }

  Future<void> _updateCourse() async {
    if (_courseNameController.text.isEmpty ||
        _courseCodeController.text.isEmpty ||
        _courseCrnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    // Upload the student list file first if it is selected
    if (_selectedFile != null) {
      final uploadSuccess = await _uploadFile(_selectedFile!, _selectedCourse!['_id'],);
      if (!uploadSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Öğrenci listesi yüklenirken bir hata oluştu')),
        );
        return;
      }
    }

    // If upload is successful or no file is selected, proceed to update the course
    final updatedCourse = await _visionAPIService.updateCourse(
      _selectedCourse!['_id'],
      _courseCodeController.text,
      _courseNameController.text,
      _courseCrnController.text,
    );

    if (updatedCourse != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders başarıyla güncellendi')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders güncellenirken bir hata oluştu')),
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _loadExcelData();
      });
    }
  }

  Future<void> _loadExcelData() async {
    var bytes = _selectedFile!.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    setState(() {
      _excelData = [];
      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          _excelData.add(row);
        }
      }
    });
  }

Future<bool> _uploadFile(File file, String courseId) async {
  var request = http.MultipartRequest(
    'POST',
    //Uri.parse('http://localhost:3030/api/student/student-create'), 
    Uri.parse('http://169.254.43.191:3030/api/student/student-create'), // Your server URL
  );
  
  // Dosyayı ekle
  request.files.add(await http.MultipartFile.fromPath('file', file.path));

  // courseId'yi ekle
  request.fields['courseId'] = courseId;

  // İstek gönderimi
  var streamedResponse = await request.send();
  print(streamedResponse);
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    print('File uploaded successfully');
    return true;
  } else {
    print('File upload failed: ${response.statusCode}');
    print('Response: ${response.body}');
    return false;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Ders Düzenle',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Düzenlemek İstediğiniz Dersin Bilgilerini Giriniz',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 18.0),
            DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedCourse,
              hint: const Text('Ders Seçin'),
              dropdownColor: Colors.white,
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  _selectedCourse = newValue!;
                  _populateFields(_selectedCourse!);
                });
              },
              items: _courses.map((course) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: course,
                  child: Text(course['courseName'] ?? 'Ders Adı Yok'),
                );
              }).toList(),
            ),
            const SizedBox(height: 18.0),
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
            const SizedBox(height: 12.0),
            TextField(
              controller: _courseCrnController,
              decoration: const InputDecoration(
                labelText: 'Ders CRN\'si',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateCourse,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 4, 4, 67)),
              ),
              child: const Text(
                'Güncelle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 4, 4, 67)),
              ),
              child: const Text(
                'Öğrenci Listesini Yükle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null) ...[
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Expanded(child: Text('Seçilen Dosya: ${_selectedFile!.path.split('/').last}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
