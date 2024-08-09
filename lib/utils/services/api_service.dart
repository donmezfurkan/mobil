import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getUserToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("userToken");
}

Future<String?> getUserName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("userName");
}

Future<String?> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

class APIConstants {
  static const String baseURL = 'http://localhost:3030/api/';
  //static const String baseURL = 'http://169.254.241.104:3030/api/';   //tel ip
  //static const String baseURL = 'http://169.254.40.200:3030/api/'; //ev ip
}

class VisionAPIService {
  final String apiKey =
      'AIzaSyAIJt-mH4drNMMzikRk_v1LbmSjWSY8HZY'; // Google Cloud Vision API anahtarı

  VisionAPIService();

  Future<Map<String, dynamic>?> detectText(String base64Image) async {
    final String url =
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        // Başarılı istek
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String extractedText =
            data['responses'][0]['fullTextAnnotation']['text'];
        // İşlem sonrası veri haritasını oluştur
        Map<String, dynamic> dataMap = {
          'Student Number': '',
          'scores': [],
          'Total': ''
        };

        // Eğer response boşsa veya null ise boş bir map döndür
        if (extractedText.isEmpty) {
          return dataMap;
        }

        // Response'ı satır bazında ayır
        List<String> lines = extractedText.split('\n');

        // Verileri işle ve istediğin formata dönüştür
        bool isReadingScores = false;
        List<String?> scores = [];
        for (int i = 0; i < lines.length; i++) {
          String line =
              lines[i].trim(); // Satır başı ve sonundaki boşlukları temizle

          if (line.contains('Student Number')) {
            dataMap['Student Number'] = line
                .replaceAll('Student Number', '')
                .trim(); // Öğrenci numarasını ayıkla ve ekle
            continue;
          }

          if (line.contains('Grades')) {
            isReadingScores =
                true; // 'Grades' satırından sonraki satırları scores olarak oku
            continue;
          }

          if (line.contains('Total:')) {
            dataMap['Total'] = line.split(':')[1].trim(); // Total puanını ekle
            isReadingScores = false;
            continue;
          }

          if (isReadingScores) {
            // Q ile başlayan satırları belirleyin
            if (line.startsWith('Q')) {
              // Mevcut Q numarasını bulun
              int qNumber = int.parse(line.split(':')[0].substring(1));

              // Q numarasına kadar olan boşlukları doldur
              while (scores.length < qNumber) {
                scores.add(null);
              }
            } else if (scores.isNotEmpty) {
              // Son eklenen Q numarasının değerini güncelle
              scores[scores.length - 1] = line;
            }
          }
        }

        dataMap['scores'] =
            scores.map((e) => e == null ? 0 : int.parse(e)).toList();
        return dataMap;
      } else {
        // Hata durumu
        print('Hata kodu: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Hata oluştu
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    const String apiUrl = '${APIConstants.baseURL}user-profile/getuserProfile';
    //const String apiUrl = 'http://172.20.10.2:3030/api/userProfile';

    String? userToken = await getUserToken();
    String? userName = await getUserName();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    Map<String, String> requestBody = {
      "userName": userName ?? "",
    };

    String requestBodyJson = jsonEncode(requestBody);
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUserProfile(String username, String firstLastName, String email) async {
    const String apiUrl = '${APIConstants.baseURL}user-profile/editUserProfile';
    //const String apiUrl = 'http://172.20.10.2:3030/api/userProfile';

    String? userToken = await getUserToken();
    String? userName = await getUserName();
    String? id = await getUserId();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    Map<String, String> requestBody = {
      "userId": id.toString(),
      "userName": username,
      "firstLastName": firstLastName,
      "email": email,
    };

    String requestBodyJson = jsonEncode(requestBody);
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<List<dynamic>?> fetchCourses() async {
    const String apiUrl = '${APIConstants.baseURL}courses/course-show';
    //const String apiUrl = 'http://172.20.10.2:3030/api/courses/course-show';

    String? userToken = await getUserToken();
    String? id = await getUserId();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    Map<String, String> requestBody = {"userId": id.toString()};

    String requestBodyJson = jsonEncode(requestBody);
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['courseArray'] is List) {
          return data['courseArray'] as List<dynamic>;
        } else {
          print('Unexpected data format: ${data.runtimeType}');
          return null;
        }
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCourse(
      String courseCode, String courseName, String courseCrn) async {
    const String apiUrl = '${APIConstants.baseURL}courses/course-create';

    String? userToken = await getUserToken();
    String? id = await getUserId();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    // Map<String, String> requestBody = {
    //   "courseId": courseId,
    //   "examName": examId,
    //   "questionNumber": questionCount.toString(),
    // };
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'courseName': courseName,
          'courseCode': courseCode,
          'courseCRN': courseCrn,
          "userId": id.toString()
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateCourse(String courseId, String courseCode,
      String courseName, String courseCrn) async {
    const String apiUrl = '${APIConstants.baseURL}courses/course-edit';

    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    // Map<String, String> requestBody = {
    //   "courseId": courseId,
    //   "examName": examId,
    //   "questionNumber": questionCount.toString(),
    // };
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'courseId': courseId,
          'courseName': courseName,
          'courseCode': courseCode,
          'courseCRN': courseCrn
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteCourse(String courseId) async {
    const String apiUrl = '${APIConstants.baseURL}courses/course-delete';

    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    // Map<String, String> requestBody = {
    //   "courseId": courseId,
    //   "examName": examId,
    //   "questionNumber": questionCount.toString(),
    // };
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'courseId': courseId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<List<dynamic>?> fetchExam(String selecttedId) async {
    const String apiUrl = '${APIConstants.baseURL}exam/exam-show';

    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    Map<String, String> requestBody = {
      "courseId": selecttedId,
    };

    String requestBodyJson = jsonEncode(requestBody);
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['examArray'] is List) {
          return data['examArray'] as List<dynamic>;
        } else {
          print('Unexpected data format: ${data.runtimeType}');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('Hata kodu: 404 - Course not found');
        return []; // 404 durumunda boş liste döndür
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createExam(
      String courseId,
      String examName,
      int questionCount,
      int totalScore,
      List<Map<String, dynamic>> questionDetails) async {
    const String apiUrl = '${APIConstants.baseURL}exam/exam-create';
    print(questionDetails);
    String? userToken = await getUserToken();
    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    Map<String, dynamic> requestBody = {
      'courseId': courseId,
      'examName': examName,
      'questionNumber': questionCount,
      'totalExamScore': totalScore,
      'questionDetails': questionDetails,
    };

    String requestBodyJson = jsonEncode(requestBody);
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateExam(
      String examId,
      String examName,
      int questionCount,
      int totalScore,
      List<Map<String, dynamic>> questionDetails) async {
    const String apiUrl = '${APIConstants.baseURL}exam/exam-edit';
    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    // Map<String, String> requestBody = {
    //   "courseId": courseId,
    //   "examName": examId,
    //   "questionNumber": questionCount.toString(),
    // };
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'examId': examId,
          'examName': examName,
          'questionNumber': questionCount,
          'totalExamScore': totalScore,
          'questionDetails': questionDetails,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteExam(String examId) async {
    const String apiUrl = '${APIConstants.baseURL}exam/exam-delete';

    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    // Map<String, String> requestBody = {
    //   "courseId": courseId,
    //   "examName": examId,
    //   "questionNumber": questionCount.toString(),
    // };
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'examId': examId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<http.Response> createGrade(
      String examId, Map<String, dynamic> grades) async {
    String? userToken = await getUserToken();
    const String apiUrl = '${APIConstants.baseURL}grade/grade-create';
    if (userToken == null) {
      print('Token bulunamadı.');
      return http.Response('Token bulunamadı.', 400);
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };

    String studentId = grades['Student Number'];
    List<int> scoresList = List<int>.from(grades['scores']);

    Map<String, int> scores = {};
    for (int i = 0; i < scoresList.length; i++) {
      scores[(i + 1).toString()] = scoresList[i];
    }

    Map<String, dynamic> requestBody = {
      "examId": examId,
      "students": [
        {
          "studentId": studentId,
          "scores": scores,
        }
      ]
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print('Notlar başarıyla kaydedildi.');
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
      }
      return response;
    } catch (e) {
      print('Hata: $e');
      return http.Response('Hata: $e', 500);
    }
  }

  Future<Map<String, dynamic>?> gradeShow(String examId) async {
    String? userToken = await getUserToken();
    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };

    Map<String, dynamic> requestBody = {"examId": examId};

    String requestBodyJson = jsonEncode(requestBody);
    final response = await http.post(
      Uri.parse('${APIConstants.baseURL}grade/grade-show'),
      headers: headers,
      body: requestBodyJson,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to show grades');
    }
  }

  Future<Map<String, dynamic>?> fetchAbet() async {
    const String apiUrl = '${APIConstants.baseURL}abet/abet-show';

    String? userToken = await getUserToken();

    if (userToken == null) {
      print('Token bulunamadı.');
      return null;
    }
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };
    try {
      final http.Response response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Hata kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<bool> uploadStudentList(File file, String courseId) async {
    const String apiUrl = '${APIConstants.baseURL}student/student-create';
    final mimeTypeData = lookupMimeType(file.path)?.split('/');
    if (mimeTypeData == null) {
      print('Could not determine the file type');
      return false; // Could not determine the file type
    }

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..fields['courseId'] = courseId // courseId ekliyoruz
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));
    print(request);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('File uploaded successfully');
        return true;
      } else {
        print('Failed to upload file. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }
}
