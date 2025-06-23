import 'package:json_annotation/json_annotation.dart';

part 'technician_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TechnicianProfile {
  final String fullName;
  final String profession;
  final String phoneNumber;
  final String location;
  final String email;
  @JsonKey(name: 'technicianId')
  final String id;
  final List<String> skills;
  final double rating;
  @JsonKey(name: 'reviewCount')
  final int totalReviews;
  @JsonKey(name: 'jobsCompleted')
  final int completedJobs;
  @JsonKey(name: 'totalJobs')
  final int jobsAvailable;

  TechnicianProfile({
    required this.fullName,
    required this.profession,
    required this.phoneNumber,
    required this.location,
    required this.email,
    required this.id,
    required this.skills,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    required this.jobsAvailable,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) =>
      _$TechnicianProfileFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianProfileToJson(this);
}
