import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';
import 'api.dart';

class AuthService {
  /// Kullanıcı kayıt olma metodu
  Future<bool> registerUser(
      String name, String email, String password, String confirmPassword, String disabilityType) async {
    print("📌 Kayıt işlemi başlatıldı: $name, $email, $password, $confirmPassword, $disabilityType");

    String formattedDisabilityType = _formatDisabilityType(disabilityType);

    final Map<String, dynamic> requestBody = {
      "nameSurname": name,
      "email": email,
      "password": password,
      "confirmPassword": confirmPassword,
      "disabilityType": formattedDisabilityType,  // ENUM DÖNÜŞTÜRÜLDÜ!
    };

    print("📌 Gönderilen JSON: ${jsonEncode(requestBody)}");

    final response = await http.post(
      Uri.parse(Api.register),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print("📌 API Yanıt Kodu: ${response.statusCode}");
    print("📌 API Yanıtı: ${response.body}");

    return response.statusCode == 200;
  }

  /// Kullanıcı giriş yapma metodu
  Future<bool> loginUser(String email, String password) async {
    print("📌 Kullanıcı giriş yapmaya çalışıyor: $email");

    final response = await http.post(
      Uri.parse(Api.login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    print("📌 API Yanıt Kodu: ${response.statusCode}");
    print("📌 API Yanıtı: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String token = data["token"];
      String refreshToken = data["refreshToken"];

      // 🌟 JWT Token'ı decode edip disability_type çekiyoruz
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      String? disabilityType = payload["disability_type"]; // 📌 Buradan geliyor

      print("📌 Çözümlenen disabilityType: $disabilityType");

      // 🌟 Tokenları ve disability_type'ı kaydediyoruz
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", token);
      await prefs.setString("refresh_token", refreshToken);
      await prefs.setString("user_email", email);
      if (disabilityType != null) {
        await prefs.setString("disability_type", disabilityType);
      }

      print("✅ Kullanıcı giriş yaptı, token ve disabilityType kaydedildi.");
      return true;
    }

    return false;
  }

  /// Kullanıcının oturum açık olup olmadığını kontrol eden metot
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") != null;
  }

  /// Refresh Token kullanarak yeni JWT almak için metot
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString("refresh_token");
    String? email = prefs.getString("user_email");

    if (refreshToken == null || email == null) {
      print("❌ Refresh Token veya email bulunamadı.");
      return false;
    }

    print("🔄 Refresh Token ile yeni JWT alınıyor...");

    final response = await http.post(
      Uri.parse(Api.refresh),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "refreshToken": refreshToken
      }),
    );

    print("📌 API Yanıt Kodu: ${response.statusCode}");
    print("📌 API Yanıtı: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String newToken = data["token"];
      String newRefreshToken = data["refreshToken"];

      await prefs.setString("jwt_token", newToken);
      await prefs.setString("refresh_token", newRefreshToken);

      // 🌟 BURAYI EKLİYORUZ
      Map<String, dynamic> payload = Jwt.parseJwt(newToken);
      String? newDisabilityType = payload["disability_type"];
      if (newDisabilityType != null) {
        await prefs.setString("disability_type", newDisabilityType);
        print("✅ Yeni disabilityType kaydedildi: $newDisabilityType");
      } else {
        print("⚠️ Yeni token içinde disabilityType bulunamadı.");
      }

      print("✅ Yeni token başarıyla alındı.");
      return true;
    } else {
      print("❌ Refresh Token geçersiz, tekrar giriş gerekli.");
      return false;
    }
  }


  /// Kullanıcı çıkış işlemi
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      await http.post(
        Uri.parse('http://192.168.0.3:5298/api/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    }

    // Localden token'ı ve diğer bilgileri temizle
    await prefs.clear();
  }

  Future<UserModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");

    if (token == null) return null;

    final response = await http.get(
      Uri.parse(Api.getProfile),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    print("📌 GET Profile yanıt kodu: ${response.statusCode}");
    print("📌 Yanıt içeriği: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      return null;
    }
  }



  /// Kullanıcının seçtiği `DisabilityType` değerini API'nin beklediği ENUM formatına çevirir
  String _formatDisabilityType(String userInput) {
    Map<String, String> disabilityMap = {
      "Visually Impaired": "VisuallyImpaired",
      "Hard Hearing Impaired": "HardHearingImpaired"
    };

    return disabilityMap[userInput] ?? "VisuallyImpaired"; // Varsayılan değer
  }
}
