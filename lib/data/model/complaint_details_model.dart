import 'package:json_annotation/json_annotation.dart';

part 'complaint_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ComplaintDetailsModel {
  final bool success;
  final Message message;
  final ComplaintData data;

  ComplaintDetailsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ComplaintDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDetailsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDetailsModelToJson(this);
}

@JsonSerializable()
class Message {
  final String en;
  final String ar;

  Message({required this.en, required this.ar});

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ComplaintData {
  @JsonKey(name: 'complaint_id')
  final String complaintId;
  @JsonKey(name: 'complaint_number')
  final String complaintNumber;
  final String category;
  final String subcategory;
  final String description;
  final String reply;
  @JsonKey(name: 'amount_paid')
  final String amountPaid;
  @JsonKey(name: 'amount_paid_status')
  final String amountPaidStatus;
  final Status status;
  @JsonKey(name: 'last_updated')
  final String lastUpdated;
  final Property property;
  final ComplaintImages images;

  ComplaintData({
    required this.complaintId,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.reply,
    required this.amountPaid,
    required this.amountPaidStatus,
    required this.status,
    required this.lastUpdated,
    required this.property,
    required this.images,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);
}

@JsonSerializable()
class Status {
  final String en;

  Status({required this.en});

  factory Status.fromJson(Map<String, dynamic> json) =>
      _$StatusFromJson(json);

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
class Property {
  final String title;
  @JsonKey(name: 'unit_number')
  final String unitNumber;
  @JsonKey(name: 'address_format')
  final String addressFormat;
  @JsonKey(name: 'unit_type')
  final String unitType;

  Property({
    required this.title,
    required this.unitNumber,
    required this.addressFormat,
    required this.unitType,
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class ComplaintImages {
  @JsonKey(name: 'tenant_images')
  final List<String> tenantImages;
  @JsonKey(name: 'technician_images')
  final List<String> technicianImages;

  ComplaintImages({
    required this.tenantImages,
    required this.technicianImages,
  });

  factory ComplaintImages.fromJson(Map<String, dynamic> json) =>
      _$ComplaintImagesFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintImagesToJson(this);
}
