// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianProfile _$TechnicianProfileFromJson(Map<String, dynamic> json) =>
    TechnicianProfile(
      uid: json['uid'] as String,
      location: json['location'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      photoURL: json['photoURL'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$TechnicianProfileToJson(TechnicianProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'location': instance.location,
      'fullName': instance.fullName,
      'email': instance.email,
      'mobile': instance.mobile,
      'photoURL': instance.photoURL,
      'role': instance.role,
    };
