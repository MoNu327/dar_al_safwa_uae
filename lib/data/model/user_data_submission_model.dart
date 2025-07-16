import 'package:json_annotation/json_annotation.dart';
import 'document_submission_model.dart';
part 'user_data_submission_model.g.dart';

@JsonSerializable()
class UserDataSubmissionModel {
  @JsonKey(name: 'uid')
  final String uid;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'last_name')
  final String lastName;

  @JsonKey(name: 'propertyid')
  final String propertyId;

  @JsonKey(name: 'unitid')
  final String unitId;

  @JsonKey(name: 'address')
  final String address;
  final String nationality;
  final String email;
  final String mobile;
  @JsonKey(name: 'passport_no')
  final String passportNo;
  @JsonKey(name: 'visa_no')
  final String visaNo;
  final List<DocumentSubmission> fields;

  UserDataSubmissionModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.nationality,
    required this.email,
    required this.mobile,
    required this.propertyId,
    required this.unitId,
    required this.passportNo,
    required this.visaNo,
    required this.fields,
  });

  factory UserDataSubmissionModel.fromJson(Map<String, dynamic> json) =>
      _$UserDataSubmissionModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataSubmissionModelToJson(this);
}
