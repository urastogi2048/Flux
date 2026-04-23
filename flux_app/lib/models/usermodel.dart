//this is common user model assigned to both admin and vol
class UserModel{
  String uid;
  List<String> ngoid;
  String name;
  String email;
  String role; // admin or volunteer
  String? phone;
  String? profileImage;
  DateTime createdAt;
  bool isActive;
  UserModel({
    required this.uid,
    required this.ngoid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true, // By default, user is active upon signup
    this.phone,
    this.profileImage,
  });
}