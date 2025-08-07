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
  final int propertyId;

  @JsonKey(name: 'unitid')
  final int unitId;

  @JsonKey(name: 'address')
  final String address;

  @JsonKey(name: 'citizenship')
  final int citizenship; // 0 = foreign, 1 = native

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'mobile')
  final String mobile;

  // Native citizen fields (required when citizenship = 1)
  @JsonKey(name: 'civil_id', includeIfNull: false)
  final String? civilId;

  @JsonKey(name: 'civil_id_expiry', includeIfNull: false)
  final String? civilIdExpiry; // Use String for date format (YYYY-MM-DD)

  // Foreign citizen fields (required when citizenship = 0)
  @JsonKey(name: 'passport_no', includeIfNull: false)
  final String? passportNo;

  @JsonKey(name: 'visa_no', includeIfNull: false)
  final String? visaNo;

  @JsonKey(name: 'visa_expiry_date', includeIfNull: false)
  final String? visaExpiryDate; // Use String for date format (YYYY-MM-DD)

  @JsonKey(name: 'expat_civil_id', includeIfNull: false)
  final String? expatCivilId;

  @JsonKey(name: 'expat_civil_id_expiry', includeIfNull: false)
  final String? expatCivilIdExpiry; // Use String for date format (YYYY-MM-DD)

  // Document arrays
  @JsonKey(name: 'required_documents', includeIfNull: false)
  final List<String>? requiredDocuments; // File paths or base64 strings

  @JsonKey(name: 'required_document_types')
  final List<String> requiredDocumentTypes; // Document type identifiers

  @JsonKey(name: 'additional_documents', includeIfNull: false)
  final List<String>? additionalDocuments; // File paths or base64 strings

  @JsonKey(name: 'additional_document_titles', includeIfNull: false)
  final List<String>? additionalDocumentTitles;

  // Legacy field support (you might want to remove this if not needed)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<DocumentSubmission>? fields;

  UserDataSubmissionModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.citizenship,
    required this.email,
    required this.mobile,
    required this.propertyId,
    required this.unitId,
    required this.requiredDocumentTypes,
    this.civilId,
    this.civilIdExpiry,
    this.passportNo,
    this.visaNo,
    this.visaExpiryDate,
    this.expatCivilId,
    this.expatCivilIdExpiry,
    this.requiredDocuments,
    this.additionalDocuments,
    this.additionalDocumentTitles,
    this.fields,
  });

  // Validation helper methods
  bool get isNative => citizenship == 1;
  bool get isForeign => citizenship == 0;

  // Validation method to check required fields based on citizenship
  bool isValid() {
    if (isNative) {
      return civilId != null && 
             civilIdExpiry != null && 
             requiredDocumentTypes.isNotEmpty;
    } else if (isForeign) {
      return passportNo != null && 
             visaNo != null && 
             visaExpiryDate != null && 
             expatCivilId != null && 
             expatCivilIdExpiry != null && 
             requiredDocumentTypes.isNotEmpty;
    }
    return false;
  }

  factory UserDataSubmissionModel.fromJson(Map<String, dynamic> json) =>
      _$UserDataSubmissionModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataSubmissionModelToJson(this);

  // Helper method to create a model for native citizens
  factory UserDataSubmissionModel.native({
    required String uid,
    required String firstName,
    required String lastName,
    required String address,
    required String email,
    required String mobile,
    required int propertyId,
    required int unitId,
    required String civilId,
    required String civilIdExpiry,
    required List<String> requiredDocumentTypes,
    List<String>? requiredDocuments,
    List<String>? additionalDocuments,
    List<String>? additionalDocumentTitles,
  }) {
    return UserDataSubmissionModel(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      address: address,
      citizenship: 1,
      email: email,
      mobile: mobile,
      propertyId: propertyId,
      unitId: unitId,
      civilId: civilId,
      civilIdExpiry: civilIdExpiry,
      requiredDocumentTypes: requiredDocumentTypes,
      requiredDocuments: requiredDocuments,
      additionalDocuments: additionalDocuments,
      additionalDocumentTitles: additionalDocumentTitles,
    );
  }

  // Helper method to create a model for foreign citizens
  factory UserDataSubmissionModel.foreign({
    required String uid,
    required String firstName,
    required String lastName,
    required String address,
    required String email,
    required String mobile,
    required int propertyId,
    required int unitId,
    required String passportNo,
    required String visaNo,
    required String visaExpiryDate,
    required String expatCivilId,
    required String expatCivilIdExpiry,
    required List<String> requiredDocumentTypes,
    List<String>? requiredDocuments,
    List<String>? additionalDocuments,
    List<String>? additionalDocumentTitles,
  }) {
    return UserDataSubmissionModel(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      address: address,
      citizenship: 0,
      email: email,
      mobile: mobile,
      propertyId: propertyId,
      unitId: unitId,
      passportNo: passportNo,
      visaNo: visaNo,
      visaExpiryDate: visaExpiryDate,
      expatCivilId: expatCivilId,
      expatCivilIdExpiry: expatCivilIdExpiry,
      requiredDocumentTypes: requiredDocumentTypes,
      requiredDocuments: requiredDocuments,
      additionalDocuments: additionalDocuments,
      additionalDocumentTitles: additionalDocumentTitles,
    );
  }
}