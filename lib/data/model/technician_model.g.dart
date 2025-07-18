// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianProfile _$TechnicianProfileFromJson(Map<String, dynamic> json) =>
    TechnicianProfile(
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      id: json['technicianId'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$TechnicianProfileToJson(TechnicianProfile instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'technicianId': instance.id,
      'role': instance.role,
    };
