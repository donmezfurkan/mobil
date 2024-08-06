import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 4, 67),
        title: const Text('Hakkında', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uygulama Hakkında',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Bu uygulama, öğrenci ve öğretim üyelerinin ders ve sınav süreçlerini yönetmelerine yardımcı olmak amacıyla geliştirilmiştir. '
                'Uygulama, kullanıcı dostu arayüzü ve güçlü özellikleri ile öğrenci bilgilerini, sınav notlarını ve ders materyallerini kolayca yönetmeyi sağlar.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Özellikler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '- Kullanıcı dostu profil yönetimi: Kullanıcılar profil bilgilerini kolayca güncelleyebilir ve kişiselleştirebilir.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '- Ders ve sınav yönetimi: Öğretim üyeleri derslerini ve sınavlarını kolayca oluşturabilir, düzenleyebilir ve notları yönetebilir.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '- Öğrenci bilgileri: Öğrenciler ders ve sınav bilgilerine kolayca erişebilir ve notlarını görüntüleyebilir.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '- Dosya yükleme ve yönetimi: Kullanıcılar ders materyallerini ve sınav belgelerini kolayca yükleyebilir ve yönetebilir.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Teknolojiler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Bu uygulama, Flutter framework kullanılarak geliştirilmiştir. Flutter, hem Android hem de iOS platformlarında yüksek performanslı, nativ benzeri uygulamalar oluşturmayı sağlayan açık kaynaklı bir UI yazılım geliştirme kitidir.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Backend servisler, Node.js ve Express framework kullanılarak geliştirilmiştir ve MongoDB veritabanı ile entegre edilmiştir.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Geliştirici Ekibi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Bu uygulama, deneyimli yazılım geliştiriciler ve eğitim teknolojileri uzmanlarından oluşan bir ekip tarafından geliştirilmiştir. '
                'Amacımız, eğitim süreçlerini daha verimli ve etkili hale getirmektir.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'İletişim',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Herhangi bir sorunuz veya geri bildiriminiz için bizimle iletişime geçebilirsiniz: donmezf16@itu.edu.tr and  kaya22@itu.edu.tr',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
