class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatar;

  UserModel({required this.id, required this.email, required this.name, this.avatar});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }
}
//