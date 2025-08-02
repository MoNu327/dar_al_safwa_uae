import 'dart:io';

class CreateComplaintRequest {
  final int complaintMasterId;
  final int complaintSubtitleId;
  final String description;
  final String userId;
  final String propertyName;
  final int propertyId;
  final int unitAddressId;
  // final List<File> images;

  CreateComplaintRequest({
    required this.complaintMasterId,
    required this.complaintSubtitleId,
    required this.description,
    required this.userId,
    required this.propertyName,
    required this.propertyId,
    required this.unitAddressId,
        // required this.images,

  });

  Map<String, dynamic> toJson() {
    return {
      'complaint_master_id': complaintMasterId,
      'complaint_subtitle_id': complaintSubtitleId,
      'description': description,
      'user_id': userId,
      'property_id': propertyId,
      'unit_address_id': unitAddressId,
      'property_name': propertyName,
      // 'images': images.map((image) => image.path).toList(),
    };
  }
}
