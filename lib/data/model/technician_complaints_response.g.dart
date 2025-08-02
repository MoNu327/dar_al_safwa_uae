// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_complaints_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianComplaintsResponse _$TechnicianComplaintsResponseFromJson(
        Map<String, dynamic> json) =>
    TechnicianComplaintsResponse(
      status: TechnicianComplaintsResponse.statusFromJson(json['success']),
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : ComplaintResponseData.fromJson(
              json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TechnicianComplaintsResponseToJson(
        TechnicianComplaintsResponse instance) =>
    <String, dynamic>{
      'success': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

ComplaintResponseData _$ComplaintResponseDataFromJson(
        Map<String, dynamic> json) =>
    ComplaintResponseData(
      complaint: json['complaint'] == null
          ? null
          : Complaints.fromJson(json['complaint'] as Map<String, dynamic>),
      property: json['property'] == null
          ? null
          : Property.fromJson(json['property'] as Map<String, dynamic>),
      directImages:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      adminInfo: json['adminInfo'] == null
          ? null
          : AdminInfo.fromJson(json['adminInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintResponseDataToJson(
        ComplaintResponseData instance) =>
    <String, dynamic>{
      'complaint': instance.complaint,
      'property': instance.property,
      'images': instance.directImages,
      'adminInfo': instance.adminInfo,
    };

Complaints _$ComplaintsFromJson(Map<String, dynamic> json) => Complaints(
      complaintId: Complaints._readComplaintId(json, 'complaintId') as String?,
      complaintNumber: json['complaint_number'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String?,
      reply: json['reply'] as String?,
      replyByAdmin: json['reply_by_admin'] as String?,
      amountPaid: json['amount_paid'] as String?,
      amountPaidStatus: json['amount_paid_status'] as String?,
      statusCode: Complaints._statusCodeFromJson(json['status']),
      status: json['status_text'] == null
          ? null
          : Status.fromJson(json['status_text'] as Map<String, dynamic>),
      createdAt: Complaints._readCreatedAt(json, 'createdAt') as String?,
      lastUpdated: json['last_updated'] as String?,
      lastUpdatedByAdmin: json['last_updated_by_admin'] as String?,
      addedByAdmin: json['added_by_admin'] as bool?,
      propertyName: json['property_name'] as String?,
      unitNumber: json['unit_number'] as String?,
      fullAddress: json['full_address'] as String?,
      flatnoId: json['flatno_id'] as String?,
    );

Map<String, dynamic> _$ComplaintsToJson(Complaints instance) =>
    <String, dynamic>{
      'complaintId': instance.complaintId,
      'complaint_number': instance.complaintNumber,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'description': instance.description,
      'reply': instance.reply,
      'reply_by_admin': instance.replyByAdmin,
      'amount_paid': instance.amountPaid,
      'amount_paid_status': instance.amountPaidStatus,
      'status': instance.statusCode,
      'status_text': instance.status,
      'createdAt': instance.createdAt,
      'last_updated': instance.lastUpdated,
      'last_updated_by_admin': instance.lastUpdatedByAdmin,
      'added_by_admin': instance.addedByAdmin,
      'property_name': instance.propertyName,
      'unit_number': instance.unitNumber,
      'full_address': instance.fullAddress,
      'flatno_id': instance.flatnoId,
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      en: json['en'] as String?,
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'en': instance.en,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: json['id'] as String?,
      title: json['title'] as String?,
      unit: json['unit'] == null
          ? null
          : PropertyUnit.fromJson(json['unit'] as Map<String, dynamic>),
      assignedTechnicians: (json['assigned_technicians'] as List<dynamic>?)
          ?.map((e) => Technician.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentTechnician: json['current_technician'] == null
          ? null
          : Technician.fromJson(
              json['current_technician'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'unit': instance.unit,
      'assigned_technicians': instance.assignedTechnicians,
      'current_technician': instance.currentTechnician,
    };

PropertyUnit _$PropertyUnitFromJson(Map<String, dynamic> json) => PropertyUnit(
      number: json['number'] as String?,
      addressFormat: json['address_format'] as String?,
      unitType: json['type'] as String?,
    );

Map<String, dynamic> _$PropertyUnitToJson(PropertyUnit instance) =>
    <String, dynamic>{
      'number': instance.number,
      'address_format': instance.addressFormat,
      'type': instance.unitType,
    };

Technician _$TechnicianFromJson(Map<String, dynamic> json) => Technician(
      assignmentId: json['assignment_id'] as String?,
      uid: json['uid'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      assignedAt: json['assigned_at'] as String?,
      status: json['status'] as String?,
      isCurrent: json['is_current'] as bool?,
    );

Map<String, dynamic> _$TechnicianToJson(Technician instance) =>
    <String, dynamic>{
      'assignment_id': instance.assignmentId,
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'photo': instance.photo,
      'assigned_at': instance.assignedAt,
      'status': instance.status,
      'is_current': instance.isCurrent,
    };

TechnicianImages _$TechnicianImagesFromJson(Map<String, dynamic> json) =>
    TechnicianImages(
      tenantUploads: (json['tenant_uploads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      adminUploads: (json['admin_uploads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      technicianUploads: (json['technician_uploads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$TechnicianImagesToJson(TechnicianImages instance) =>
    <String, dynamic>{
      'tenant_uploads': instance.tenantUploads,
      'admin_uploads': instance.adminUploads,
      'technician_uploads': instance.technicianUploads,
      'images': instance.images,
    };

AdminInfo _$AdminInfoFromJson(Map<String, dynamic> json) => AdminInfo(
      addedByAdmin: json['added_by_admin'] as bool?,
      lastUpdatedByAdmin: json['last_updated_by_admin'] as String?,
      replyByAdmin: json['reply_by_admin'] as String?,
      adminUploadedImagesCount:
          (json['admin_uploaded_images_count'] as num?)?.toInt(),
      adminTechnicianImagesCount:
          (json['admin_technician_images_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AdminInfoToJson(AdminInfo instance) => <String, dynamic>{
      'added_by_admin': instance.addedByAdmin,
      'last_updated_by_admin': instance.lastUpdatedByAdmin,
      'reply_by_admin': instance.replyByAdmin,
      'admin_uploaded_images_count': instance.adminUploadedImagesCount,
      'admin_technician_images_count': instance.adminTechnicianImagesCount,
    };
