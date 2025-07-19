import 'package:json_annotation/json_annotation.dart';

part 'technician_model.g.dart';

@JsonSerializable()
class TechnicianProfile {
  final String uid;
  final String location;
  final String fullName;
  final String email;
  final String mobile;
  final String photoURL;
  final String role;

  TechnicianProfile({
    required this.uid,
    required this.location,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.photoURL,
    required this.role,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) =>
      _$TechnicianProfileFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianProfileToJson(this);
}
