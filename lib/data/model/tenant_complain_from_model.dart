import 'package:json_annotation/json_annotation.dart';

part 'tenant_complain_from_model.g.dart';

@JsonSerializable()
class TenantComplainFromModel {
  @JsonKey(name: 'complaint_master_id')
  final int complaintMasterId;

  @JsonKey(name: 'complaint_subtitle_id')
  final int complaintSubtitleId;

  final String description;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'property_id')
  final int propertyId;

  @JsonKey(name: 'unit_address_id')
  final int unitAddressId;

  final List<String> images;

  TenantComplainFromModel({
    required this.complaintMasterId,
    required this.complaintSubtitleId,
    required this.description,
    required this.userId,
    required this.propertyId,
    required this.unitAddressId,
    required this.images,
  });

  factory TenantComplainFromModel.fromJson(Map<String, dynamic> json) =>
      _$TenantComplainFromModelFromJson(json);

  Map<String, dynamic> toJson() => _$TenantComplainFromModelToJson(this);
}
