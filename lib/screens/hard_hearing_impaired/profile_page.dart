import 'package:flutter/material.dart';
import 'package:soulspeakma/model/user_model.dart';
import 'package:soulspeakma/screens/base_scaffold.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/login_page.dart';
import 'package:soulspeakma/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await _authService.getProfile();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Container(
        color: const Color(0xFF36EEE0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : _user == null
            ? Center(child: Text("User information could not be loaded ❌", style: TextStyle(color: Colors.white)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Color(0xFF36EEE0)),
              ),
              SizedBox(height: 16),
              Text(
                "Welcome, ${_user!.nameSurname}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 24),
              _infoCard(Icons.person, "Name Surname", _user!.nameSurname),
              _infoCard(Icons.email, "Email", _user!.email),
              _infoCard(Icons.accessibility, "Disability Type", _formatDisability(_user!.disabilityType)),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout),
                label: Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF36EEE0),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF36EEE0)),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  String _formatDisability(String apiValue) {
    switch (apiValue) {
      case "VisuallyImpaired":
        return "Visually Impaired";
      case "HardHearingImpaired":
        return "Hard Hearing Impaired";
      default:
        return apiValue;
    }
  }
}
