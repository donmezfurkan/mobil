import 'package:flutter/material.dart';
import 'package:scanitu/utils/services/api_service.dart';

class ProfileUpdatePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ProfileUpdatePage({Key? key, required this.userProfile}) : super(key: key);

  @override
  _ProfileUpdatePageState createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final VisionAPIService _visionAPIService = VisionAPIService();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstLastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFields(widget.userProfile);
  }

  void _populateFields(Map<String, dynamic> profile) {
    _userNameController.text = profile['userName'] ?? '';
    _firstLastNameController.text = profile['firstLastName'] ?? '';
    _emailController.text = profile['email'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (_userNameController.text.isEmpty ||
        _firstLastNameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final updatedProfile = await _visionAPIService.updateUserProfile(
      _userNameController.text,
      _firstLastNameController.text,
      _emailController.text,
    );

    if (updatedProfile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellenirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text(
          'Profil Güncelle',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Profil Bilgilerini Giriniz',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _firstLastNameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
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
    );
  }
}
