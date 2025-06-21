class UserModel {
  final String? uid;
  final String? email;
  final String? name;
  final String role;
  final String status;
  final String? phoneNumber;
  final String? location;

  UserModel({
    required this.uid,
    this.email,
    this.name,
    required this.role,
    this.location,
    required this.status,
    this.phoneNumber,
  });

  // Add this copyWith method
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? status,
    String? phoneNumber,
    String? location,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  // Convert JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      location: json['location'],
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'pending',
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'phoneNumber': phoneNumber,
        'name': name,
        'role': role,
        'status': status,
        'location': location,
      };
}
