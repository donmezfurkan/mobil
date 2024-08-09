import 'package:flutter/material.dart';
import 'package:scanitu/utils/services/api_service.dart';

class EditExamPage extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> exam;

  const EditExamPage({super.key, required this.courseId, required this.exam});

  @override
  _EditExamPageState createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _questionCountController = TextEditingController();
  final TextEditingController _totalScoreController = TextEditingController();
  List<TextEditingController> _questionScoreControllers = [];
  List<Map<String, String>> _abetCriteria = [];
  List<List<String>> _selectedAbetCodes = [];
  List<String> _percentageValues = [];

  @override
  void initState() {
    super.initState();
    _fetchAbetCriteria();
    _populateFields(widget.exam);
  }

  void _populateFields(Map<String, dynamic> exam) {
    _examNameController.text = exam['examName'] ?? '';
    _questionCountController.text = (exam['questionNumber'] ?? '').toString();
    _totalScoreController.text = (exam['totalExamScore'] ?? '').toString();

    List<dynamic> questionDetails = exam['questionDetails'] ?? [];
    _questionScoreControllers = List.generate(
      questionDetails.length,
      (index) => TextEditingController(text: questionDetails[index]['points'].toString()),
    );

    _selectedAbetCodes = List.generate(
      questionDetails.length,
      (index) => List<String>.from(questionDetails[index]['abetCriteria'] ?? []),
    );

    _calculatePercentages();
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
          _matchAbetCriteriaWithIds();
        });
      } else {
        throw Exception('Failed to fetch ABET criteria');
      }
    } catch (error) {
      print('Error fetching ABET criteria: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ABET kriterleri alınırken bir hata oluştu')),
      );
    }
  }

  void _matchAbetCriteriaWithIds() {
    for (int i = 0; i < _selectedAbetCodes.length; i++) {
      List<String> abetIds = _selectedAbetCodes[i];
      _selectedAbetCodes[i] = abetIds.map((id) {
        return _abetCriteria.firstWhere((criteria) => criteria['id'] == id, orElse: () => {'code': ''})['code']!;
      }).toList();
    }
    setState(() {});
  }

  Future<void> _updateExam() async {
    int totalScore = int.tryParse(_totalScoreController.text) ?? 0;
    int sumOfScores = _questionScoreControllers.fold(0, (sum, controller) => sum + (int.tryParse(controller.text) ?? 0));

    if (sumOfScores != totalScore) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Hata'),
          content: const Text('Soru puanlarının toplamı, toplam skora eşit olmalıdır.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    if (_examNameController.text.isEmpty || _questionCountController.text.isEmpty || _totalScoreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    List<Map<String, dynamic>> questionDetails = [];
    for (int i = 0; i < _questionScoreControllers.length; i++) {
      questionDetails.add({
        'questionNumber': i + 1,
        'points': int.parse(_questionScoreControllers[i].text),
        'abetCriteria': _selectedAbetCodes[i].map((code) {
          return _abetCriteria.firstWhere((criteria) => criteria['code'] == code)['id']!;
        }).toList(),
      });
    }

    final success = await _visionAPIService.updateExam(
      widget.exam['_id'],
      _examNameController.text,
      int.parse(_questionCountController.text),
      int.parse(_totalScoreController.text),
      questionDetails,
    );

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınav başarıyla güncellendi')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınav güncellenirken bir hata oluştu')),
      );
    }
  }

  void _updateCreateButtonState() {
    setState(() {
      _calculatePercentages();
    });
  }

  void _calculatePercentages() {
    int totalScore = int.tryParse(_totalScoreController.text) ?? 0;
    if (totalScore > 0) {
      _percentageValues = _questionScoreControllers.map((controller) {
        int questionScore = int.tryParse(controller.text) ?? 0;
        double percentage = (questionScore / totalScore) * 100;
        return percentage.toStringAsFixed(2) + '%';
      }).toList();
    } else {
      _percentageValues = List.filled(_questionScoreControllers.length, '0%');
    }
  }

  void _showAbetSelectionDialog(int questionIndex) async {
    List<String> selectedCodes = List.from(_selectedAbetCodes[questionIndex]);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('ABET Kodlarını Seçin'),
              content: SingleChildScrollView(
                child: Column(
                  children: _abetCriteria.map((criteria) {
                    return CheckboxListTile(
                      title: Text('${criteria['code']} - ${criteria['description']}'),
                      value: selectedCodes.contains(criteria['code']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!selectedCodes.contains(criteria['code'])) {
                              selectedCodes.add(criteria['code']!);
                            }
                          } else {
                            selectedCodes.remove(criteria['code']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAbetCodes[questionIndex] = selectedCodes;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  void _removeAbetCode(int questionIndex, String code) {
    setState(() {
      _selectedAbetCodes[questionIndex].remove(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text('Sınav Düzenle', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Sınav Bilgilerini Giriniz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _examNameController,
                decoration: const InputDecoration(
                  labelText: 'Sınav Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: _questionCountController,
                decoration: const InputDecoration(
                  labelText: 'Soru Sayısı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  int questionCount = int.tryParse(value) ?? 0;
                  setState(() {
                    _questionScoreControllers = List.generate(questionCount, (_) => TextEditingController());
                    _selectedAbetCodes = List.generate(questionCount, (_) => []);
                    _percentageValues = List.filled(questionCount, '0%');
                    _updateCreateButtonState();
                  });
                },
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: _totalScoreController,
                decoration: const InputDecoration(
                  labelText: 'Toplam Puan',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _updateCreateButtonState();
                },
              ),
              const SizedBox(height: 20),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(), // Disable the scrolling in ListView
                shrinkWrap: true, // Make the ListView wrap its content
                itemCount: _questionScoreControllers.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soru ${index + 1}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _questionScoreControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'Soru Puanı',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _updateCreateButtonState();
                        },
                      ),
                      const SizedBox(height: 8.0),
                      if (_totalScoreController.text.isNotEmpty && _questionScoreControllers[index].text.isNotEmpty)
                        Text(
                          'Yüzde: ${_percentageValues[index]}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8.0),
                      InkWell(
                        onTap: () {
                          _showAbetSelectionDialog(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _selectedAbetCodes[index].isEmpty
                                ? 'ABET Kodu Seçin'
                                : 'Seçilen ABET Kodları: ${_selectedAbetCodes[index].join(', ')}',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Divider(color: Colors.grey),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateExam,
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
            ],
          ),
        ),
      ),
    );
  }
}
