class Api {
  static const String baseUrl = "http://192.168.1.83:5298/api/Auth"; // Backend URL
  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String refresh = "$baseUrl/refresh";
  static const String getProfile = "http://192.168.1.83:5298/api/User/me";

}
