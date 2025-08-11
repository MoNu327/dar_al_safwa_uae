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

  // Commercial property fields (required for commercial properties)
  @JsonKey(name: 'cr_number', includeIfNull: false)
  final String? crNumber;

  @JsonKey(name: 'cr_expiry_date', includeIfNull: false)
  final String? crExpiryDate; // Use String for date format (YYYY-MM-DD)

  @JsonKey(name: 'municipality_license_number', includeIfNull: false)
  final String? municipalityLicenseNumber;

  @JsonKey(name: 'municipality_license_date', includeIfNull: false)
  final String? municipalityLicenseDate; // Use String for date format (YYYY-MM-DD)

  @JsonKey(name: 'company_address', includeIfNull: false)
  final String? companyAddress;

  @JsonKey(name: 'po_box', includeIfNull: false)
  final String? poBox;

  @JsonKey(name: 'property_type', includeIfNull: false)
  final String? propertyType; // 'residential' or 'commercial'

  // Backend status fields (usually not set from frontend)
  @JsonKey(name: 'flag', includeIfNull: false)
  final int? flag;

  @JsonKey(name: 'status', includeIfNull: false)
  final int? status;

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
    this.crNumber,
    this.crExpiryDate,
    this.municipalityLicenseNumber,
    this.municipalityLicenseDate,
    this.companyAddress,
    this.poBox,
    this.propertyType,
    this.flag,
    this.status,
    this.requiredDocuments,
    this.additionalDocuments,
    this.additionalDocumentTitles,
    this.fields,
  });




UserDataSubmissionModel copyWith({
  String? uid,
  String? firstName,
  String? lastName,
  int? propertyId,
  int? unitId,
  String? address,
  int? citizenship,
  String? email,
  String? mobile,
  String? civilId,
  String? civilIdExpiry,
  String? passportNo,
  String? visaNo,
  String? visaExpiryDate,
  String? expatCivilId,
  String? expatCivilIdExpiry,
  String? crNumber,
  String? crExpiryDate,
  String? municipalityLicenseNumber,
  String? municipalityLicenseDate,
  String? companyAddress,
  String? poBox,
  String? propertyType,
  int? flag,
  int? status,
  List<String>? requiredDocuments,
  List<String>? requiredDocumentTypes,
  List<String>? additionalDocuments,
  List<String>? additionalDocumentTitles,
}) {
  return UserDataSubmissionModel(
    uid: uid ?? this.uid,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    propertyId: propertyId ?? this.propertyId,
    unitId: unitId ?? this.unitId,
    address: address ?? this.address,
    citizenship: citizenship ?? this.citizenship,
    email: email ?? this.email,
    mobile: mobile ?? this.mobile,
    civilId: civilId ?? this.civilId,
    civilIdExpiry: civilIdExpiry ?? this.civilIdExpiry,
    passportNo: passportNo ?? this.passportNo,
    visaNo: visaNo ?? this.visaNo,
    visaExpiryDate: visaExpiryDate ?? this.visaExpiryDate,
    expatCivilId: expatCivilId ?? this.expatCivilId,
    expatCivilIdExpiry: expatCivilIdExpiry ?? this.expatCivilIdExpiry,
    crNumber: crNumber ?? this.crNumber,
    crExpiryDate: crExpiryDate ?? this.crExpiryDate,
    municipalityLicenseNumber: municipalityLicenseNumber ?? this.municipalityLicenseNumber,
    municipalityLicenseDate: municipalityLicenseDate ?? this.municipalityLicenseDate,
    companyAddress: companyAddress ?? this.companyAddress,
    poBox: poBox ?? this.poBox,
    propertyType: propertyType ?? this.propertyType,
    flag: flag ?? this.flag,
    status: status ?? this.status,
    requiredDocuments: requiredDocuments ?? this.requiredDocuments,
    requiredDocumentTypes: requiredDocumentTypes ?? this.requiredDocumentTypes,
    additionalDocuments: additionalDocuments ?? this.additionalDocuments,
    additionalDocumentTitles: additionalDocumentTitles ?? this.additionalDocumentTitles,
    fields: this.fields, 
  );
}

  // Validation helper methods
  bool get isNative => citizenship == 1;
  bool get isForeign => citizenship == 0;
  bool get isCommercial => propertyType == 'commercial';
  bool get isResidential => propertyType == 'residential';

  // Validation method to check required fields based on citizenship and property type
  bool isValid() {
    // Check base required fields
    if (requiredDocumentTypes.isEmpty) return false;

    // Check citizenship-specific fields
    if (isNative) {
      if (civilId == null || civilIdExpiry == null) return false;
    } else if (isForeign) {
      if (passportNo == null || 
          visaNo == null || 
          visaExpiryDate == null || 
          expatCivilId == null || 
          expatCivilIdExpiry == null) return false;
    }

    // Check commercial property fields
    if (isCommercial) {
      if (crNumber == null || 
          crExpiryDate == null || 
          municipalityLicenseNumber == null || 
          municipalityLicenseDate == null || 
          companyAddress == null || 
          poBox == null) return false;
    }

    return true;
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
    String? propertyType,
    List<String>? requiredDocuments,
    List<String>? additionalDocuments,
    List<String>? additionalDocumentTitles,
    // Commercial fields
    String? crNumber,
    String? crExpiryDate,
    String? municipalityLicenseNumber,
    String? municipalityLicenseDate,
    String? companyAddress,
    String? poBox,
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
      propertyType: propertyType ?? 'residential',
      requiredDocuments: requiredDocuments,
      additionalDocuments: additionalDocuments,
      additionalDocumentTitles: additionalDocumentTitles,
      crNumber: crNumber,
      crExpiryDate: crExpiryDate,
      municipalityLicenseNumber: municipalityLicenseNumber,
      municipalityLicenseDate: municipalityLicenseDate,
      companyAddress: companyAddress,
      poBox: poBox,
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
    String? propertyType,
    List<String>? requiredDocuments,
    List<String>? additionalDocuments,
    List<String>? additionalDocumentTitles,
    // Commercial fields
    String? crNumber,
    String? crExpiryDate,
    String? municipalityLicenseNumber,
    String? municipalityLicenseDate,
    String? companyAddress,
    String? poBox,
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
      propertyType: propertyType ?? 'residential',
      requiredDocuments: requiredDocuments,
      additionalDocuments: additionalDocuments,
      additionalDocumentTitles: additionalDocumentTitles,
      crNumber: crNumber,
      crExpiryDate: crExpiryDate,
      municipalityLicenseNumber: municipalityLicenseNumber,
      municipalityLicenseDate: municipalityLicenseDate,
      companyAddress: companyAddress,
      poBox: poBox,
    );
  }

  // Helper method to create a commercial property model
  factory UserDataSubmissionModel.commercial({
    required String uid,
    required String firstName,
    required String lastName,
    required String address,
    required String email,
    required String mobile,
    required int propertyId,
    required int unitId,
    required int citizenship,
    required List<String> requiredDocumentTypes,
    required String crNumber,
    required String crExpiryDate,
    required String municipalityLicenseNumber,
    required String municipalityLicenseDate,
    required String companyAddress,
    required String poBox,
    // Citizenship specific fields
    String? civilId,
    String? civilIdExpiry,
    String? passportNo,
    String? visaNo,
    String? visaExpiryDate,
    String? expatCivilId,
    String? expatCivilIdExpiry,
    List<String>? requiredDocuments,
    List<String>? additionalDocuments,
    List<String>? additionalDocumentTitles,
  }) {
    return UserDataSubmissionModel(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      address: address,
      citizenship: citizenship,
      email: email,
      mobile: mobile,
      propertyId: propertyId,
      unitId: unitId,
      requiredDocumentTypes: requiredDocumentTypes,
      propertyType: 'commercial',
      crNumber: crNumber,
      crExpiryDate: crExpiryDate,
      municipalityLicenseNumber: municipalityLicenseNumber,
      municipalityLicenseDate: municipalityLicenseDate,
      companyAddress: companyAddress,
      poBox: poBox,
      civilId: civilId,
      civilIdExpiry: civilIdExpiry,
      passportNo: passportNo,
      visaNo: visaNo,
      visaExpiryDate: visaExpiryDate,
      expatCivilId: expatCivilId,
      expatCivilIdExpiry: expatCivilIdExpiry,
      requiredDocuments: requiredDocuments,
      additionalDocuments: additionalDocuments,
      additionalDocumentTitles: additionalDocumentTitles,
    );
  }
}