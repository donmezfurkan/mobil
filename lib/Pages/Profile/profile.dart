import 'package:flutter/material.dart';
import 'package:scanitu/utils/services/api_service.dart'; // VisionAPIService'yi içe aktardık

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userImage;
  const ProfilePage({Key? key, required this.userName, required this.userImage}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    fetchUserProfileData();
  }

  Future<void> fetchUserProfileData() async {
    final userProfile = await _visionAPIService.fetchUserProfile();
    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile['userProfile'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bilgileri alınırken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _userProfile['firstLastName'] ?? "John Doe";
    final String userEmail = _userProfile['userName'] ?? "john.doe@example.com";
    final String userImage = _userProfile['userImage'] ?? "assets/profile_image.png";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text('Profil Sayfası', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              //backgroundImage: AssetImage(userImage),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Text(
              'Profil sayfası içeriği burada olacak.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
