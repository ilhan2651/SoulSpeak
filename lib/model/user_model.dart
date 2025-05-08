class UserModel {
  final String nameSurname;
  final String email;
  final String disabilityType;

  UserModel({
    required this.nameSurname,
    required this.email,
    required this.disabilityType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nameSurname: json['nameSurname'],
      email: json['email'],
      disabilityType: json['disabilityType'],
    );
  }
}
