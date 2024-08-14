import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:scanitu/utils/services/api_service.dart';

class ExamDetailPage extends StatefulWidget {
  final String courseId;
  final String examId;
  final String examName;
  final Map<String, dynamic> exam;
  final Map<String, dynamic> examofCourse;

  const ExamDetailPage(
      {Key? key,
      required this.courseId,
      required this.examId,
      required this.examName,
      required this.exam,
      required this.examofCourse})
      : super(key: key);

  @override
  _ExamDetailPageState createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  List<Map<String, dynamic>> students = [];
  bool _isLoading = true;
  bool _isEmpty = false;

  TextEditingController studentIdController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  List<TextEditingController> questionControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    try {
      final response = await _visionAPIService.gradeShow(widget.examId);
      if (response != null &&
          response['gradeArray'] != null &&
          response['gradeArray'].isNotEmpty) {
        setState(() {
          students = List<Map<String, dynamic>>.from(response['gradeArray']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isEmpty = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isEmpty = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notlar alınırken bir hata oluştu')),
      );
    }
  }

  void _editStudentScores(Map<String, dynamic> student) {
    TextEditingController studentNumberController =
        TextEditingController(text: student['studentId'].toString());
    List<TextEditingController> scoreControllers = student['scores']
        .map<TextEditingController>(
            (score) => TextEditingController(text: score.toString()))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Not Düzenle - ${student['studentId']}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: studentNumberController,
                  decoration:
                      const InputDecoration(labelText: 'Öğrenci Numarası'),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < scoreControllers.length; i++)
                  TextField(
                    controller: scoreControllers[i],
                    decoration:
                        InputDecoration(labelText: 'Soru ${i + 1} Puanı'),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  student['studentId'] =
                      int.parse(studentNumberController.text);
                  student['scores'] = scoreControllers
                      .map((controller) => int.parse(controller.text))
                      .toList();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Kaydet',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
          ],
        );
      },
    );
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
        final File imageFile = File(result.path);

        // Read image
        List<int> imageBytes = await imageFile.readAsBytes();
        Uint8List uint8ListImageBytes = Uint8List.fromList(imageBytes);
        img.Image originalImage = img.decodeImage(uint8ListImageBytes)!;

        // Apply grayscale
        img.Image preprocessedImage = img.grayscale(originalImage);

        // Apply Gaussian Blur
        preprocessedImage = img.gaussianBlur(preprocessedImage, radius: 1);

        // Apply Thresholding (assuming a fixed threshold of 128)
        preprocessedImage = applyThreshold(preprocessedImage, 128);

        // Adjust contrast if needed
        preprocessedImage = adjustContrast(preprocessedImage, 1.2);

        // Convert the processed image back to base64
        List<int> processedImageBytes = img.encodeJpg(preprocessedImage);
        String base64String = base64Encode(processedImageBytes);

        // Upload the image
        await _uploadImage(base64String);
      }
    } catch (e) {
      print('Failed to take picture: $e');
    }
  }

  img.Image applyThreshold(img.Image image, int threshold) {
    img.Image thresholded = img.Image.from(image);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        num luma = img.getLuminance(image.getPixel(x, y));
        // if (luma < threshold) {
        //   thresholded.setPixel(x, y, img.getColor(0, 0, 0));
        // } else {
        //   thresholded.setPixel(x, y, img.getColor(255, 255, 255));
        // }
      }
    }
    return thresholded;
  }

  img.Image adjustContrast(img.Image image, double contrast) {
    return img.adjustColor(image, contrast: contrast);
  }

  Future<void> _uploadImage(String base64Image) async {
    try {
      Map<String, dynamic>? dataMap =
          await _visionAPIService.detectText(base64Image);
      if (dataMap != null) {
        _populateFields(dataMap);
      }
    } catch (e) {
      print('Image upload failed: $e');
      _showErrorDialog(context, 'Image upload failed: $e');
    }
  }

  void _populateFields(Map<String, dynamic> dataMap) {
    studentIdController.text = dataMap['Student Number'] ?? '';
    List<dynamic> scores = dataMap['scores'] ?? [];
    questionControllers =
        List.generate(scores.length, (index) => TextEditingController());
    for (int i = 0; i < scores.length; i++) {
      questionControllers[i].text = scores[i].toString();
    }
    totalController.text = dataMap['Total'] ?? '';
    _showDetectedDataPopup();
  }

  void _showDetectedDataPopup() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Popup'ın klavye kapatıldığında kapanmamasını sağlar
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Detected Data'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: studentIdController,
                  decoration:
                      const InputDecoration(labelText: 'Öğrenci Numarası'),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < questionControllers.length; i++)
                  TextField(
                    controller: questionControllers[i],
                    decoration:
                        InputDecoration(labelText: 'Soru ${i + 1} Puanı'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(labelText: 'Total Puan'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveGrade,
              child: const Text('Kaydet',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGrade() async {
    String studentNumberStr = studentIdController.text;
    int? studentNumber = int.tryParse(studentNumberStr);

    if (studentNumber == null) {
      _showErrorDialog(context, 'Geçersiz öğrenci numarası.');
      return;
    }

    // Öğrenci numarasının examofCourse arrayinde olup olmadığını kontrol et
    bool isStudentRegistered =
        widget.examofCourse['students'].contains(studentNumber);

    if (!isStudentRegistered) {
      bool? shouldSave = await _showConfirmationDialog();
      if (shouldSave == null || !shouldSave) {
        // Kullanıcı hayır dediyse işlemi iptal et
        return;
      }
    }

    Map<String, dynamic> gradeData = {
      'Student Number': studentNumberStr,
      'scores': questionControllers
          .map((controller) => int.tryParse(controller.text) ?? 0)
          .toList(),
      'Total': int.tryParse(totalController.text) ?? 0,
    };

    try {
      final response =
          await _visionAPIService.createGrade(widget.examId, gradeData);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not başarıyla kaydedildi')),
        );
        Navigator.of(context).pop();
        _fetchGrades(); // Öğrenci tablosunu yenile
      } else {
        print('Not kaydedilemedi: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not kaydedilemedi: ${response.statusCode}')),
        );
        _showErrorDialog(context, 'Not kaydedilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Not kaydedilemedi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not kaydedilemedi: $e')),
      );
      _showErrorDialog(context, 'Not kaydedilemedi: $e');
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Öğrenci Numarası Bulunamadı'),
          content: const Text(
              'Bu öğrenci numarası bu derse kayıtlı değil, yine de kaydetmek ister misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet',
                  style: TextStyle(color: Color.fromARGB(255, 4, 4, 67))),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

 Future<void> _sendEmailWithExcel() async {
  try {
    final response = await _visionAPIService.sendMail(widget.examId);
    
    if (response!['status'] == 200) {
      _showSuccessDialog(context, response['message']);
    } else {
      _showErrorDialog(context, 'Mail gönderilemedi: ${response['message']}');
    }

  } catch (e) {
    print('Mail Gönderilemedi: $e');
    _showErrorDialog(context, 'Mail Gönderilemedi: $e');
  }
}

void _showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Success'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK',style: TextStyle(color: Color.fromARGB(255, 4, 4, 67)),),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: Text(widget.examName,
            style: const TextStyle(fontSize: 24, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _sendEmailWithExcel,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isEmpty
                  ? const Center(
                      child: Text('Herhangi bir not oluşturulmamıştır.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Öğrenci Tablosu',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Notları kaydedilen öğrenciler',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                const DataColumn(
                                    label: Text('Öğrenci No')),
                                for (int i = 0;
                                    i < widget.exam['questionNumber'];
                                    i++)
                                  DataColumn(label: Text('Soru ${i + 1}')),
                                const DataColumn(label: Text('Toplam')),
                                const DataColumn(label: Text('Düzenle')),
                              ],
                              rows: students.map((student) {
                                int totalScore = student['scores'].fold(
                                    0, (sum, score) => sum + (score ?? 0));
                                return DataRow(
                                  cells: [
                                    DataCell(
                                        Text(student['studentId'].toString())),
                                    for (int i = 0;
                                        i < widget.exam['questionNumber'];
                                        i++)
                                      DataCell(Text(
                                          student['scores'][i]?.toString() ??
                                              '')),
                                    DataCell(Text(totalScore.toString())),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _editStudentScores(student),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _takePicture,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                const Color.fromARGB(255, 4, 4, 67)),
                          ),
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ],
                    ),
        ),
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
      _showErrorDialog(context, 'Failed to take picture: $e');
    }
  }

  Future<File> _cropImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image originalImage = img.decodeImage(bytes)!;

    const int targetWidth = 400;
    const int targetHeight = 100;

    // Resmi orantılı olarak yeniden boyutlandır
    img.Image resizedImage;
    if ((originalImage.width / originalImage.height) >
        (targetWidth / targetHeight)) {
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
    final File croppedFile = File(path)
      ..writeAsBytesSync(img.encodePng(croppedImage));

    return croppedFile;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Take a picture',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller),
                ),
                Center(
                  child: Container(
                    width: 400,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
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
                  child: Container(
                      color: Colors.black54,
                      width: (MediaQuery.of(context).size.width - 400) / 2),
                ),
                Positioned(
                  top: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  right: 0,
                  bottom: (MediaQuery.of(context).size.height - 100) / 2 + 50,
                  child: Container(
                      color: Colors.black54,
                      width: (MediaQuery.of(context).size.width - 400) / 2),
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
