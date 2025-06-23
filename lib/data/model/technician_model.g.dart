// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianProfile _$TechnicianProfileFromJson(Map<String, dynamic> json) =>
    TechnicianProfile(
      fullName: json['fullName'] as String,
      profession: json['profession'] as String,
      phoneNumber: json['phoneNumber'] as String,
      location: json['location'] as String,
      email: json['email'] as String,
      id: json['technicianId'] as String,
      skills:
          (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
      rating: (json['rating'] as num).toDouble(),
      totalReviews: (json['reviewCount'] as num).toInt(),
      completedJobs: (json['jobsCompleted'] as num).toInt(),
      jobsAvailable: (json['totalJobs'] as num).toInt(),
    );

Map<String, dynamic> _$TechnicianProfileToJson(TechnicianProfile instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'profession': instance.profession,
      'phoneNumber': instance.phoneNumber,
      'location': instance.location,
      'email': instance.email,
      'technicianId': instance.id,
      'skills': instance.skills,
      'rating': instance.rating,
      'reviewCount': instance.totalReviews,
      'jobsCompleted': instance.completedJobs,
      'totalJobs': instance.jobsAvailable,
    };
