import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/home_page_hard_hearing_impaired.dart';
import 'package:soulspeakma/screens/visually_impaired/router_voice_command_page.dart';

import '../services/auth_service.dart';
import 'DisabilitySelectionPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authService = AuthService();
    final prefs = await SharedPreferences.getInstance();

    bool isLoggedIn = await authService.isLoggedIn();
    String? disabilityType = prefs.getString("disability_type");

    Future.delayed(Duration(seconds: 3), () async {
      if (!isLoggedIn) {
        print("🚪 Kullanıcı giriş yapmamış, DisabilitySelectionPage'e yönlendiriliyor...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DisabilitySelectionPage()),
        );
        return;
      }

      print("🔄 Kullanıcı oturum açık görünüyor, Refresh Token kontrol ediliyor...");
      bool tokenRefreshed = await authService.refreshToken();

      if (tokenRefreshed) {
        print("✅ Token yenilendi. Kullanıcının engel durumu: $disabilityType");

        if (disabilityType == "VisuallyImpaired") {
          print("🚀 Kullanıcı StarterPageVisuallyImpaired'e yönlendiriliyor...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RouterVoiceCommandPage()),
          );
        } else if (disabilityType == "HardHearingImpaired") {
          print("🚀 Kullanıcı StarterPageHardHearingImpaired'e yönlendiriliyor...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePageHardHearing()),
          );
        } else {
          print("⚠️ Kullanıcının engel türü belirlenemedi, varsayılan sayfaya yönlendiriliyor.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DisabilitySelectionPage()),
          );
        }
      } else {
        print("❌ Refresh Token geçersiz, tekrar kayıt gerekli.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DisabilitySelectionPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF36EEE0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Expanded(
            flex: 3,
            child: Center(
              child: Image.asset("assets/images/33.png", width: 650, height: 500),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: Center(
              child: Lottie.asset(
                "assets/animations/Animation1.json",
                width: 400,
                height: 400,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
