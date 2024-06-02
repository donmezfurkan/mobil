import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getUserToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("userToken");
}

class VisionAPIService {
  final String apiKey = 'AIzaSyAIJt-mH4drNMMzikRk_v1LbmSjWSY8HZY'; // Google Cloud Vision API anahtarı

  VisionAPIService();

  Future<String?> detectText(String base64Image) async {
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
        //print(response.body);
        print(extractedText);
        return extractedText;
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


  Future<List<dynamic>?> fetchCourses() async {
    const String apiUrl = 'http://localhost:3030/api/courses/course-show';
    //const String apiUrl = 'http://172.20.10.2:3030/api/courses/course-show';

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
      "userId": '665c6d79bf7ec9193ab5c091',
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
        print(data);
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

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    const String apiUrl = 'http://localhost:3030/api/userProfile';
    //const String apiUrl = 'http://172.20.10.2:3030/api/userProfile';

    

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
      "userName": 'furkan',
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
}