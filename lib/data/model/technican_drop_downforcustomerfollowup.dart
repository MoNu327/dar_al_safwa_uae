class Supervisor {
  final String uid;
  final String fullName;
  final String email;
  final String mobile;
  final String role;
  final String? assignedAt;

  Supervisor({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.role,
    this.assignedAt,
  });

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? '',
      assignedAt: json['assigned_at'],
    );
  }
}