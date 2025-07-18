import 'package:json_annotation/json_annotation.dart';

part 'update_complaint_request.g.dart';

@JsonSerializable()
class UpdateComplaintRequest {
  @JsonKey(name: 'complaint_id')
  final int complaintId;

  final int status;
  final String reply;

  @JsonKey(name: 'amount_paid')
  final int amountPaid;

  @JsonKey(name: 'amount_status')
  final int amountStatus;

  final List<String>? images;

  UpdateComplaintRequest({
    required this.complaintId,
    required this.status,
    required this.reply,
    required this.amountPaid,
    required this.amountStatus,
    this.images,
  });

  factory UpdateComplaintRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateComplaintRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateComplaintRequestToJson(this);
}
