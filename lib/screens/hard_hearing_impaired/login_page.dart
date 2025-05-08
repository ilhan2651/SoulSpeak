import 'package:flutter/material.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/home_page_hard_hearing_impaired.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/starter_page.dart';

import '../../services/auth_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController=TextEditingController();
  final TextEditingController _passwordController=TextEditingController();
  bool _isLoading=false;
  String _errorMessage="";
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false, // geri tuşunu engelle
    child: Scaffold(
      backgroundColor: Color(0xFF36EEE0),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
                "assets/images/33.png",
              width: 400,
              height: 400,
            ),
            SizedBox(height: 20),
            Text(
              "Sign In",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please enter your email and password to login",
              style: TextStyle(fontSize: 14,color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                )
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            SizedBox(height: 20),

          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Sign In",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),


          ],
        ),
      ),
    )
    );
  }
  void _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Please fill in all fields.";
      });
      return;
    }

    bool success = await AuthService().loginUser(email, password);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePageHardHearing()));
    } else {
      setState(() {
        _errorMessage = "Login failed. Please check your credentials.";
      });
    }
  }

}
