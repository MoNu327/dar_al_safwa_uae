class AgentModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String status;
  final String location;
  final String gender;
  final String dob;

  AgentModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.dob,
    required this.gender,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'status': status,
        'dob': dob,
        'gender': gender,
        'location': location,
      };
}
