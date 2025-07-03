import 'package:json_annotation/json_annotation.dart';

part 'user_data_submission_model.g.dart';

@JsonSerializable()
class UserDataSubmissionModel {
  final String firstName;
  final String lastName;
  final String address;
  final String poNo;
  final String nationality;
  final String email;
  final String mobile;
  final String passportNo;
  final String visaNo;

  UserDataSubmissionModel({
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.poNo,
    required this.nationality,
    required this.email,
    required this.mobile,
    required this.passportNo,
    required this.visaNo,
  });

  /// From JSON factory
  factory UserDataSubmissionModel.fromJson(Map<String, dynamic> json) =>
      _$UserDataSubmissionModelFromJson(json);

  /// To JSON method
  Map<String, dynamic> toJson() => _$UserDataSubmissionModelToJson(this);
}
