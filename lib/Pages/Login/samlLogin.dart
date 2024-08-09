import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SamlLoginPage extends StatefulWidget {
  @override
  _SamlLoginPageState createState() => _SamlLoginPageState();
}

class _SamlLoginPageState extends State<SamlLoginPage> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
    WebView.platform = SurfaceAndroidWebView();
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SAML Login'),
      ),
      body: WebView(
        initialUrl: 'https://girisv3.itu.edu.tr/saml/login.aspx',
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (String url) {
          if (url.contains('/login/callback')) {
            // Kullanıcı başarıyla kimlik doğrulandı
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
