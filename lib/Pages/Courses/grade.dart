import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:scanitu/utils/services/api_service.dart';

class EnterGradePage extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> courses;

  const EnterGradePage({Key? key, required this.courses}) : super(key: key);

  @override
  _EnterGradePageState createState() => _EnterGradePageState();
}

class _EnterGradePageState extends State<EnterGradePage> {
  String? selectedCourse;
  String? selectedExam;
  File? _imageFile;
  String? base64String;
  String? selectedCourseId;
  String? selectedExamId;

  List<dynamic>? fetchedCourses;
  List<dynamic>? fetchedExams;
  List<dynamic>? detectedTexts;

  Map<int, List<int>> _categorizedGrades = {};
  List<Map<String, dynamic>> ResponseImageArray = [];
  Map<String, dynamic> detectedDataMap = {};

  final VisionAPIService _visionAPIService = VisionAPIService();

  final _formKey = GlobalKey<FormState>();

  // Input form controllers
  TextEditingController studentIdController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  List<TextEditingController> questionControllers = [];

  @override
  void initState() {
    super.initState();
    _loadCoursesFromAPI();
  }

  Future<void> _loadCoursesFromAPI() async {
    try {
      List<dynamic>? courses = await _visionAPIService.fetchCourses();
      setState(() {
        fetchedCourses = courses;
      });
    } catch (e) {
      print('Failed to load courses: $e');
    }
  }

  Future<void> _loadExamsFromAPI() async {
    try {
    List<dynamic>? exams = (await _visionAPIService.fetchExam(selectedCourseId!));
    setState(() {
      fetchedExams = exams;
    });
    } catch (e) {
      print('Failed to load exams: $e');
    }
  }

  Future<void> _showGrades() async {
    try {
      Map<String, dynamic>? response = await _visionAPIService.gradeShow(selectedExamId!);
      List<dynamic> gradeArray = response!['gradeArray'];

      // Null değerlerini 0 ile değiştirmek ve verileri öğrenci numaralarına göre kategorize etmek
      Map<int, List<int>> categorizedData = {};
      for (var grade in gradeArray) {
        int studentId = grade['studentId'];
        List<int> scores = (grade['scores'] as List<dynamic>).map<int>((score) {
          if (score == null) {
            return 0;
          } else if (score is int) {
            return score;
          } else if (score is Map<String, dynamic>) {
            return score.values.first as int;
          } else {
            return 0;
          }
        }).toList();

        categorizedData[studentId] = scores;
      }

      // Tabloyu göstermek için setState çağırın
      setState(() {
        _categorizedGrades = categorizedData;
      });
    } catch (e) {
      print('Failed to show grades: $e');
      _showErrorDialog(context, 'Failed to show grades: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                setState(() {
                  _categorizedGrades = {}; // Tablonun sıfırlanması
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(String base64Image) async {
    try {
      Map<String, dynamic>? dataMap = await _visionAPIService.detectText(base64Image);
      setState(() {
        detectedDataMap = dataMap!; // detectedDataMap'i güncelle
        _populateFields(detectedDataMap);
      });
    } catch (e) {
      print('Image upload failed: $e');
    }
  }

  void _populateFields(Map<String, dynamic> dataMap) {
    studentIdController.text = dataMap['Student Number'] ?? '';
    List<dynamic> scores = dataMap['scores'] ?? [];
    for (int i = 0; i < scores.length; i++) {
      questionControllers[i].text = scores[i].toString();
    }
    totalController.text = dataMap['Total'] ?? '';
  }

  Future<void> _takePicture() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }
      final firstCamera = cameras.first;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(camera: firstCamera),
        ),
      );

      if (result != null) {
        setState(() {
          _imageFile = result;
        });

        List<int> imagesByte = File(_imageFile!.path).readAsBytesSync();
        base64String = base64Encode(imagesByte);
        await _uploadImage(base64String!);
      }
    } catch (e) {
      print('Failed to take picture: $e');
    }
  }

  Future<void> _saveGrade() async {
    Map<String, dynamic> gradeData = {
      'Student Number': studentIdController.text,
      'scores': questionControllers.map((controller) => int.tryParse(controller.text) ?? 0).toList(),
      'Total': totalController.text
    };

    try {
      await _visionAPIService.createGrade(selectedExamId!, gradeData as Map<String, dynamic>);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade saved successfully')),
      );
      // Clear controllers
      studentIdController.clear();
      questionControllers.forEach((controller) => controller.clear());
      totalController.clear();
    } catch (e) {
      print('Failed to save grade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save grade: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Gir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (fetchedCourses != null)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Ders Seçin'),
                value: selectedCourseId, // Değişen değer
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCourseId = newValue; // Seçilen _id değeri
                    _loadExamsFromAPI();
                  });
                },
                items: fetchedCourses!.map((dynamic course) {
                  return DropdownMenuItem<String>(
                    value: course['_id'], // _id değeri
                    child: Text(course['courseName']),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir ders seçin';
                  }
                  _loadExamsFromAPI();
                  return null;
                },
              ),
            if (selectedCourseId != null && fetchedExams != null)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sınav Seçin'),
                value: selectedExamId,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedExamId = newValue;
                    _showGrades();
                    // Soru sayısına göre input alanlarını yeniden oluştur
                    int questionNumber = fetchedExams!.firstWhere((exam) => exam['_id'] == selectedExamId)['questionNumber'];
                    questionControllers = List.generate(questionNumber, (index) => TextEditingController());
                  });
                },
                items: fetchedExams!.map<DropdownMenuItem<String>>((dynamic examItem) {
                  return DropdownMenuItem<String>(
                    value: examItem['_id'].toString(),
                    child: Text(examItem['examName'].toString()),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir sınav seçin';
                  }
                  _showGrades();
                  return null;
                },
              ),
            if (_imageFile != null)
              Column(
                children: [
                  SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: {
                      0: FlexColumnWidth(2),
                      for (int i = 0; i < questionControllers.length; i++)
                        i + 1: FlexColumnWidth(1),
                      questionControllers.length + 1: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Student ID'),
                          ),
                          for (int i = 0; i < questionControllers.length; i++)
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Q${i + 1}'),
                            ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Total'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: studentIdController,
                            ),
                          ),
                          for (int i = 0; i < questionControllers.length; i++)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: questionControllers[i],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: totalController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveGrade,
                    child: const Text('Save'),
                  ),
                ],
              ),
            if (detectedTexts != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(),
                    children: _buildTableRows(detectedTexts!),
                  ),
                ),
              ),
            const SizedBox(height: 16), // Boşluk eklemek için
            if (_categorizedGrades.isNotEmpty || ResponseImageArray.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildGradesTable(_categorizedGrades, ResponseImageArray),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectedCourseId != null && selectedExamId != null
            ? _takePicture
            : null,
        child: Icon(Icons.camera),
        backgroundColor: selectedCourseId != null && selectedExamId != null
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
    );
  }

  List<TableRow> _buildTableRows(List<dynamic> texts) {
    return texts.map((text) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(text['detectedText']),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(text['confidence'].toString()),
          ),
          // Diğer sütunlar burada eklenebilir
        ],
      );
    }).toList();
  }

  Widget _buildGradesTable(Map<int, List<int>> categorizedGrades, List<Map<String, dynamic>> responseImageArray) {
    List<TableRow> rows = [
      const TableRow(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'STUDENT ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'SCORES',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ];

    rows.addAll(categorizedGrades.entries.map((entry) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(entry.key.toString()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(entry.value.join(', ')),
          ),
        ],
      );
    }).toList());

    if (responseImageArray.isNotEmpty) {
      var responseData = responseImageArray.first;
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(responseData['Student Number'].toString()),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text((responseData['scores'] as List<dynamic>).join(', ')),
            ),
          ],
        ),
      );
    }

    return Table(
      border: TableBorder.all(),
      children: rows,
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final XFile image = await _controller.takePicture();

      final File croppedImage = await _cropImage(File(image.path));

      Navigator.pop(context, croppedImage);
    } catch (e) {
      print(e);
    }
  }

  Future<File> _cropImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image originalImage = img.decodeImage(bytes)!;

    const int targetWidth = 400;
    const int targetHeight = 100;

    // Resmi orantılı olarak yeniden boyutlandır
    img.Image resizedImage;
    if ((originalImage.width / originalImage.height) > (targetWidth / targetHeight)) {
      // Genişlik fazla ise yükseklik sabit kalacak şekilde boyutlandır
      resizedImage = img.copyResize(
        originalImage,
        height: targetHeight,
      );
    } else {
      // Yükseklik fazla ise genişlik sabit kalacak şekilde boyutlandır
      resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
      );
    }

    // Merkezi kırpma işlemi
    final int x = (resizedImage.width - targetWidth) ~/ 2;
    final int y = (resizedImage.height - targetHeight) ~/ 2;

    final img.Image croppedImage = img.copyCrop(
      resizedImage,
      x: x,
      y: y,
      width: targetWidth,
      height: targetHeight,
    );

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = join(directory.path, '${DateTime.now()}.png');
    final File croppedFile = File(path)..writeAsBytesSync(img.encodePng(croppedImage));

    return croppedFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Center(
                  child: Container(
                    width: 400,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: (MediaQuery.of(context).size.height - 100) / 2 + 75,
                  child: Container(color: Colors.black54),
                ),
                Positioned(
                  top: (MediaQuery.of(context).size.height - 100) / 2 + 75,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(color: Colors.black54),
                ),
                Positioned(
                  top: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  left: 0,
                  bottom: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  child: Container(color: Colors.black54, width: (MediaQuery.of(context).size.width - 400) / 2),
                ),
                Positioned(
                  top: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  right: 0,
                  bottom: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  child: Container(color: Colors.black54, width: (MediaQuery.of(context).size.width - 400) / 2),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
