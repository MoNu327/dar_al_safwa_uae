// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantTicket _$TenantTicketFromJson(Map<String, dynamic> json) => TenantTicket(
      property: json['property'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      issue: json['issue'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TenantTicketToJson(TenantTicket instance) =>
    <String, dynamic>{
      'property': instance.property,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'issue': instance.issue,
      'images': instance.images,
    };
