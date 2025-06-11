class AgentModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String status;

  AgentModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'status': status,
      };
}
