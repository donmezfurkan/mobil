import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  //static const String baseURL = 'http://169.254.123.91:3030/api/';   //tel ip
  //static const String baseURL = 'http://192.168.1.106:3030/api/';     //ev ip
}

class VisionAPIService {
  final String apiKey = 'AIzaSyAIJt-mH4drNMMzikRk_v1LbmSjWSY8HZY'; // Google Cloud Vision API anahtarı

  

  VisionAPIService();

  Future<List?> detectText(String base64Image) async {
    final String url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    //const String apiUrl = 'http://localhost:3030/';
  
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
              'features': [{'type': 'TEXT_DETECTION'}]
            }
          ]
        }),
      );
      if (response.statusCode == 200) {
        // Başarılı istek
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String extractedText = data['responses'][0]['fullTextAnnotation']['text'];
        return processResponse(extractedText);
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



  List<dynamic> processResponse(String? responseText) {
  List<dynamic> dataList = [];

  print('res: $responseText');

  // Eğer response boşsa veya null ise boş bir liste döndür
  if (responseText == null || responseText.isEmpty) {
    return dataList;
  }

  // Response'ı satır bazında ayır
  List<String> lines = responseText.split('\n');

  // Verileri işle ve istediğin formata dönüştür
  bool isReadingScores = false;
  bool isReadingGrades = false;
  List<String> questionNumbers = [];
  List<String> grades = [];
  String? studentNumber;
  String? totalScore;
  for (String line in lines) {
    if (line.toLowerCase().contains('not')) {
      isReadingScores = false;
      isReadingGrades = true; // 'NOT' satırından sonraki satırları grades olarak oku
      continue; // 'NOT' satırını eklemiyoruz, sonrasındaki satırları ekleyeceğiz
    }

    if (isReadingScores) {
      questionNumbers.add(line);
    }

    if (isReadingGrades) {
      grades.add(line);
    }

    if (line.toLowerCase().contains('soru')) {
      isReadingScores = true;
    }
  }

  if (lines.isNotEmpty) {
    studentNumber = lines.first; // İlk satır öğrenci numarası
  }

  if (lines.isNotEmpty) {
    totalScore = lines.last; // Son satır 'Total' puanı
  }

  dataList.add(studentNumber); // Öğrenci numarasını ekle
  dataList.add(questionNumbers); // Soru numaralarını ekle
  dataList.add(grades); // Grades
  dataList.add(totalScore); // Total puanını ekle
  print(dataList);
  return dataList;
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
    Map<String, String> requestBody = {
      "userId": id.toString()
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
  
  Future<List<dynamic>?> fetchExam(String selecttedId) async {
    final String apiUrl = '${APIConstants.baseURL}exam/exam-show';

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

  Future<Map<String, dynamic>?> createExam(String courseId, String examId, int questionCount) async{
    const String apiUrl = '${APIConstants.baseURL}exam/exam-create';

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
          'examId': examId,
          'questionCount': questionCount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print(data);
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
  

  


  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final String apiUrl = '${APIConstants.baseURL}userProfile';
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
      "userName":userName ?? "",
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


  Future<void> createGrade(String examId, String studentId, List<int> scores) async {
    String? userToken = await getUserToken();
    final String apiUrl = '${APIConstants.baseURL}grade/grade-create';

    if (userToken == null) {
      print('Token bulunamadı.');
      return;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "token": userToken,
    };

    Map<String, dynamic> requestBody = {
      "examId": examId,
      "studentId": studentId,
      "scores": scores,
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
    } catch (e) {
      print('Hata: $e');
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
    final response = await http.post(
      Uri.parse('${APIConstants.baseURL}grade/grade-show'),
      headers: headers,
      body: jsonEncode({'examId': examId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to show grades');
    }
  }
}