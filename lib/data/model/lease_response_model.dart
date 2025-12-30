import 'package:json_annotation/json_annotation.dart';
import 'message_model.dart';
import 'lease_data_model.dart';

part 'lease_response_model.g.dart';

@JsonSerializable()
class LeaseResponseModel {
  final bool success;
  final MessageModel? message;
  @JsonKey(defaultValue: [])
  final List<LeaseDataModel> data;

  LeaseResponseModel({
    required this.success,
    this.message,
    required this.data,
  });

  factory LeaseResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LeaseResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaseResponseModelToJson(this);
}