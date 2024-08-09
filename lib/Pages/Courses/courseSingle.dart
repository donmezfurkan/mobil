import 'package:flutter/material.dart';
import 'package:scanitu/Pages/Courses/examCreatePage.dart';
import 'package:scanitu/Pages/Courses/examSingle.dart';
import 'package:scanitu/Pages/Courses/examEditPage.dart';
import 'package:scanitu/utils/services/api_service.dart';

class CourseSinglePage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseSinglePage({super.key, required this.course});

  @override
  _CourseSinglePageState createState() => _CourseSinglePageState();
}

class _CourseSinglePageState extends State<CourseSinglePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  List<dynamic>? _exams;
  List<Map<String, String>> _abetCriteria = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExamsAndCriteria();
  }

  Future<void> _fetchExamsAndCriteria() async {
    try {
      await _fetchAbetCriteria();
      await _fetchExams();
    } catch (error) {
      print('Error fetching exams or ABET criteria: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchExams() async {
    try {
      List<dynamic>? exams = await _visionAPIService.fetchExam(widget.course['_id']);
      setState(() {
        _exams = exams;
      });
    } catch (error) {
      if (error.toString().contains('404')) {
        setState(() {
          _exams = [];
        });
      } else {
        print('Error fetching exams: $error');
      }
    }
  }

  Future<void> _fetchAbetCriteria() async {
    try {
      final response = await _visionAPIService.fetchAbet();
      if (response != null) {
        Map<String, dynamic> abetList = response['abetList'];
        List<Map<String, String>> criteria = [];

        abetList.forEach((key, value) {
          List<dynamic> subCategories = value['subCategories'] ?? [];
          for (var subCategory in subCategories) {
            List<dynamic> subCriteria = subCategory['criteria'] ?? [];
            for (var criterion in subCriteria) {
              criteria.add({
                'id': criterion['_id'] ?? '',
                'code': criterion['code'] ?? '',
                'description': criterion['description'] ?? '',
              });
            }
          }
          List<dynamic> mainCriteria = value['criteria'] ?? [];
          for (var criterion in mainCriteria) {
            criteria.add({
              'id': criterion['_id'] ?? '',
              'code': criterion['code'] ?? '',
              'description': criterion['description'] ?? '',
            });
          }
        });

        setState(() {
          _abetCriteria = criteria;
        });
      } else {
        throw Exception('Failed to fetch ABET criteria');
      }
    } catch (error) {
      print('Error fetching ABET criteria: $error');
    }
  }

  Future<void> _createExam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExamPage(courseId: widget.course['_id']),
      ),
    );

    if (result == true) {
      _fetchExams(); // Refresh the exams list after creating a new exam
    }
  }

  Future<void> _editExam(dynamic exam) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExamPage(courseId: widget.course['_id'], exam: exam),
      ),
    );

    if (result == true) {
      _fetchExams(); // Refresh the exams list after editing the exam
    }
  }

  Future<void> _deleteExam(dynamic exam) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Sınavı Sil'),
          content: Text('"${exam['examName']}" sınavını silmek istediğinize emin misiniz?', style: TextStyle(fontSize: 16.0)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet, Sil', style: TextStyle(color: const Color.fromARGB(255, 4, 4, 67))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal', style: TextStyle(color: const Color.fromARGB(255, 4, 4, 67))),
            ),
            
          ],
        );
      },
    );

    if (confirmed) {
      Map<String, dynamic>? success = await _visionAPIService.deleteExam(exam['_id']);
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sınav başarıyla silindi')),
        );
        _fetchExams(); // Refresh the exams list after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sınav silinirken bir hata oluştu')),
        );
      }
    }
  }

  String _getAbetCode(String id) {
    return _abetCriteria.firstWhere((criteria) => criteria['id'] == id, orElse: () => {'code': ''})['code']!;
  }

  List<Widget> _buildQuestionDetails(dynamic exam) {
    List<Widget> questionDetails = [];
    List<dynamic> questions = exam['questionDetails'] ?? [];

    for (int i = 0; i < questions.length; i++) {
      String points = questions[i]['points'].toString();
      String percentage = ((questions[i]['points'] / exam['totalExamScore']) * 100).toStringAsFixed(2) + '%';
      List<String> abetCriteria = List<String>.from(questions[i]['abetCriteria'] ?? [])
          .map((id) => _getAbetCode(id))
          .toList();

      questionDetails.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Soru ${i + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(percentage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Puan: $points',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                abetCriteria.join(', '),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const Divider(), // Satırların arasında çizgi
          ],
        ),
      );
    }

    return questionDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: Text(widget.course['courseName'] ?? 'Ders Detayı', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ders Kodu: ${widget.course['courseCode']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ders Crn: ${widget.course['courseCRN'] ?? 'Ders Crn Yok'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sınavlar:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _exams == null
                      ? const Center(child: CircularProgressIndicator())
                      : _exams!.isEmpty
                          ? const Text('Henüz bir sınav oluşturulmadı.')
                          : Expanded(
                              child: ListView.builder(
                                itemCount: _exams!.length,
                                itemBuilder: (context, index) {
                                  final exam = _exams![index];
                                  return Card(
                                    color: const Color.fromARGB(255, 229, 231, 231),
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ExamDetailPage(
                                                        courseId: widget.course['_id'],
                                                        examId: exam['_id'],
                                                        examName: exam['examName'],
                                                        exam: exam,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  exam['examName'] ?? 'Sınav İsmi Yok',
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Color.fromARGB(255, 4, 4, 67)),
                                                    onPressed: () => _editExam(exam),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _deleteExam(exam),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          ..._buildQuestionDetails(exam),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createExam,
        label: const Text('Sınav Oluştur', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
      ),
    );
  }
}
