class UserModel {
  int? id;
  String username;
  String email;
  String password;

  UserModel({this.id, required this.username, required this.email, required this.password});

  // Convert a User object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
    };
  }

  // Convert a Map to a User object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
    );
  }
}
