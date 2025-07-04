// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDataSubmissionModel _$UserDataSubmissionModelFromJson(
        Map<String, dynamic> json) =>
    UserDataSubmissionModel(
      uid: json['uid'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      address: json['address'] as String,
      poNo: json['poNo'] as String,
      nationality: json['nationality'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      passportNo: json['passport_no'] as String,
      visaNo: json['visa_no'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((e) => DocumentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserDataSubmissionModelToJson(
        UserDataSubmissionModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'address': instance.address,
      'poNo': instance.poNo,
      'nationality': instance.nationality,
      'email': instance.email,
      'mobile': instance.mobile,
      'passport_no': instance.passportNo,
      'visa_no': instance.visaNo,
      'fields': instance.fields,
    };
