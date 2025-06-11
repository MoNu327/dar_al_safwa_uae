class CreateComplaintRequest {
  final int complaintMasterId;
  final int complaintSubtitleId;
  final String description;
  final String userId;
  final String propertyName;

  CreateComplaintRequest({
    required this.complaintMasterId,
    required this.complaintSubtitleId,
    required this.description,
    required this.userId,
    required this.propertyName,
  });

  Map<String, dynamic> toJson() {
    return {
      'complaint_master_id': complaintMasterId,
      'complaint_subtitle_id': complaintSubtitleId,
      'description': description,
      'user_id': userId,
      "propertyname": propertyName,
    };
  }
}
