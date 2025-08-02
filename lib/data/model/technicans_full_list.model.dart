// models/technician_model.dart
class Technician {
  final String uid;
  final String fullName;

  Technician({
    required this.uid,
    required this.fullName,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
    };
  }
}