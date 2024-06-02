import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:image/image.dart' as img;
import 'package:scanitu/utils/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, List<Map<String, dynamic>>> courses = {

    'BLG 335E': [
      {'exam': 'Quiz Exam', 'questionCount': 2},
      {'exam': 'Midterm Exam', 'questionCount': 10},
      {'exam': 'Final Exam', 'questionCount': 4},
    ],
    'BLG 336E': [
      {'exam': 'Quiz Exam', 'questionCount': 2},
      {'exam': 'Midterm Exam', 'questionCount': 4},
      {'exam': 'Final Exam', 'questionCount': 10},
    ],
    'BLG 411E': [
      {'exam': 'Quiz Exam', 'questionCount': 2},
      {'exam': 'Midterm Exam', 'questionCount': 5},
      {'exam': 'Final Exam', 'questionCount': 10},
    ],
    'BLG 413E': [
      {'exam': 'Quiz Exam', 'questionCount': 3},
      {'exam': 'Midterm Exam', 'questionCount': 5},
      {'exam': 'Final Exam', 'questionCount': 5},
    ],
    'BLG 492E': [
      {'exam': 'Quiz Exam', 'questionCount': 3},
      {'exam': 'Midterm Exam', 'questionCount': 10},
      {'exam': 'Final Exam', 'questionCount': 6},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? coursesString = prefs.getString('courses');
    if (coursesString != null) {
      setState(() {
        courses = Map<String, List<Map<String, dynamic>>>.from(json.decode(coursesString));
      });
    }
  }

  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final String coursesString = json.encode(courses);
    await prefs.setString('courses', coursesString);
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
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
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}

class CreateExamPage extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> courses;
  final Function(String, String, int) onAddExam;

  const CreateExamPage({Key? key, required this.courses, required this.onAddExam}) : super(key: key);

  @override
  _CreateExamPageState createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  String? selectedCourse;
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

  Future<void> _loadCoursesFromAPI() async {
    List<dynamic>? courses = (await _visionAPIService.fetchCourses()) as List?;
    setState(() {
      fetchedCourses = courses;
    });
  }

  void _createExam() {
    if (_formKey.currentState!.validate()) {
      widget.onAddExam(selectedCourse!, examName!, questionCount!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınav başarıyla oluşturuldu!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sınav Oluştur'),
      ),
      body: fetchedCourses == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Ders Seçin'),
                      value: selectedCourse,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCourse = newValue;
                        });
                      },
                      items: fetchedCourses!.map((dynamic course) {
                        return DropdownMenuItem<String>(
                          value: course['courseName'],
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
                      decoration: InputDecoration(labelText: 'Sınav Adı'),
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
                      decoration: InputDecoration(labelText: 'Soru Sayısı'),
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
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createExam,
                      child: Text('Sınav Oluştur'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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

  final VisionAPIService _visionAPIService = VisionAPIService();

  Future<void> _uploadImage(String base64Image) async {
    try {
      await _visionAPIService.detectText(base64Image);
    } catch (e) {
      print('Image upload failed: $e');
    }
  }

  Future<void> _takePicture() async {
    final cameras = await availableCameras();
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
      _uploadImage(base64String!);
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
            DropdownButton<String>(
              hint: Text('Ders Seçin'),
              value: selectedCourse,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCourse = newValue;
                  selectedExam = null; // Ders değiştiğinde sınavı sıfırla
                });
              },
              items: widget.courses.keys.map((String course) {
                return DropdownMenuItem<String>(
                  value: course,
                  child: Text(course),
                );
              }).toList(),
            ),
            if (selectedCourse != null)
              DropdownButton<String>(
                hint: Text('Sınav Seçin'),
                value: selectedExam,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedExam = newValue;
                  });
                },
                items: (widget.courses[selectedCourse] ?? []).map<DropdownMenuItem<String>>((Map<String, dynamic> examItem) {
                  return DropdownMenuItem<String>(
                    value: examItem['exam'].toString(),
                    child: Text(examItem['exam'].toString()),
                  );
                }).toList(),
              ),
            if (_imageFile != null) Image.file(_imageFile!),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectedCourse != null && selectedExam != null
            ? _takePicture
            : null,
        child: Icon(Icons.camera),
        backgroundColor: selectedCourse != null && selectedExam != null
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
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

  final int targetWidth = 400;
  final int targetHeight = 100;

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
      appBar: AppBar(title: Text('Take a picture')),
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
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera),
      ),
    );
  }
}















