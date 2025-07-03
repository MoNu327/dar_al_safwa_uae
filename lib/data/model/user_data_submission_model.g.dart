// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDataSubmissionModel _$UserDataSubmissionModelFromJson(
        Map<String, dynamic> json) =>
    UserDataSubmissionModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      address: json['address'] as String,
      poNo: json['poNo'] as String,
      nationality: json['nationality'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      passportNo: json['passportNo'] as String,
      visaNo: json['visaNo'] as String,
    );

Map<String, dynamic> _$UserDataSubmissionModelToJson(
        UserDataSubmissionModel instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'address': instance.address,
      'poNo': instance.poNo,
      'nationality': instance.nationality,
      'email': instance.email,
      'mobile': instance.mobile,
      'passportNo': instance.passportNo,
      'visaNo': instance.visaNo,
    };
