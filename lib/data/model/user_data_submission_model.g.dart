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
      citizenship: (json['citizenship'] as num).toInt(),
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      propertyId: (json['propertyid'] as num).toInt(),
      unitId: (json['unitid'] as num).toInt(),
      requiredDocumentTypes: (json['required_document_types'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      civilId: json['civil_id'] as String?,
      civilIdExpiry: json['civil_id_expiry'] as String?,
      passportNo: json['passport_no'] as String?,
      visaNo: json['visa_no'] as String?,
      visaExpiryDate: json['visa_expiry_date'] as String?,
      expatCivilId: json['expat_civil_id'] as String?,
      expatCivilIdExpiry: json['expat_civil_id_expiry'] as String?,
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      additionalDocuments: (json['additional_documents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      additionalDocumentTitles:
          (json['additional_document_titles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$UserDataSubmissionModelToJson(
        UserDataSubmissionModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'propertyid': instance.propertyId,
      'unitid': instance.unitId,
      'address': instance.address,
      'citizenship': instance.citizenship,
      'email': instance.email,
      'mobile': instance.mobile,
      if (instance.civilId case final value?) 'civil_id': value,
      if (instance.civilIdExpiry case final value?) 'civil_id_expiry': value,
      if (instance.passportNo case final value?) 'passport_no': value,
      if (instance.visaNo case final value?) 'visa_no': value,
      if (instance.visaExpiryDate case final value?) 'visa_expiry_date': value,
      if (instance.expatCivilId case final value?) 'expat_civil_id': value,
      if (instance.expatCivilIdExpiry case final value?)
        'expat_civil_id_expiry': value,
      if (instance.requiredDocuments case final value?)
        'required_documents': value,
      'required_document_types': instance.requiredDocumentTypes,
      if (instance.additionalDocuments case final value?)
        'additional_documents': value,
      if (instance.additionalDocumentTitles case final value?)
        'additional_document_titles': value,
    };
