import 'package:json_annotation/json_annotation.dart';

part 'complaint_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ComplaintDetailsModel {
  final bool success;
  final Message? message;
  final ComplaintData data;

  ComplaintDetailsModel({
    required this.success,
    this.message,
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
  final Complaint complaint;
  final Property property;
  final List<Payment> payments;
  final List<ComplaintImage> images;
  final List<TimelineEvent> timeline;

  ComplaintData({
    required this.complaint,
    required this.property,
    List<Payment>? payments,
    List<ComplaintImage>? images,
    List<TimelineEvent>? timeline,
  })  : payments = payments ?? [],
        images = images ?? [],
        timeline = timeline ?? [];

  factory ComplaintData.fromJson(Map<String, dynamic> json) {
    return ComplaintData(
      complaint: Complaint.fromJson(json['complaint'] as Map<String, dynamic>),
      property: Property.fromJson(json['property'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ComplaintImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List<dynamic>?)
          ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);
}
@JsonSerializable()
class Complaint {
  final String id;
  @JsonKey(name: 'complaint_number')
  final String complaintNumber;
  final String category;
  final String subcategory;
  final String description;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  Complaint({
    required this.id,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintToJson(this);
}

@JsonSerializable()
class Property {
  final String id;
  final String title;
  final Unit unit;

  Property({
    required this.id,
    required this.title,
    required this.unit,
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class Unit {
  final String number;
  @JsonKey(name: 'address_format')
  final String addressFormat;
  final String type;

  Unit({
    required this.number,
    required this.addressFormat,
    required this.type,
  });

  factory Unit.fromJson(Map<String, dynamic> json) =>
      _$UnitFromJson(json);

  Map<String, dynamic> toJson() => _$UnitToJson(this);
}

@JsonSerializable()
class Payment {
  final String timestamp;
  final String amount;
  final String status;
  final String method;

  Payment({
    required this.timestamp,
    required this.amount,
    required this.status,
    required this.method,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class ComplaintImage {
  @JsonKey(name: 'image_path')
  final String imagePath;
  final String timestamp;
  final String? type;  // Add this
  final Map<String, dynamic>? by;  // Add this

  ComplaintImage({
    required this.imagePath,
    required this.timestamp,
    this.type,
    this.by,
  });

  factory ComplaintImage.fromJson(Map<String, dynamic> json) =>
      _$ComplaintImageFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintImageToJson(this);
}
@JsonSerializable()
class TimelineEvent {
  final String type;
  final String timestamp;
  final String? message;
  final String? oldStatus;
  final String? newStatus;
  final Map<String, dynamic>? by;
  final Map<String, dynamic>? technician;

  TimelineEvent({
    required this.type,
    required this.timestamp,
    this.message,
    this.oldStatus,
    this.newStatus,
    this.by,
    this.technician,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);

  Map<String, dynamic> toJson() => _$TimelineEventToJson(this);
}