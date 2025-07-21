import 'package:json_annotation/json_annotation.dart';

part 'tenant_ticket.g.dart';

@JsonSerializable()
class TenantTicket {
  final String property;
  final String category;
  final String? subcategory;
  final String issue;
  final List<String> images;

  TenantTicket({
    required this.property,
    required this.category,
    this.subcategory,
    required this.issue,
    required this.images,
  });

  /// Convert JSON to Model
  factory TenantTicket.fromJson(Map<String, dynamic> json) =>
      _$TenantTicketFromJson(json);

  /// Convert Model to JSON
  Map<String, dynamic> toJson() => _$TenantTicketToJson(this);
}
