class ComplaintStatisticsResponse {
  final bool success;
  final TechnicanMessage? message; // Made nullable
  final TechnicanData? data; // Made nullable

  ComplaintStatisticsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ComplaintStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintStatisticsResponse(
      success: json['success'] ?? false,
      message: json['message'] != null ? TechnicanMessage.fromJson(json['message']) : null,
      data: json['data'] != null ? TechnicanData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message?.toJson(),
      'data': data?.toJson(),
    };
  }
}

class TechnicanMessage {
  final String en;
  final String ar;

  TechnicanMessage({
    required this.en,
    required this.ar,
  });

  factory TechnicanMessage.fromJson(Map<String, dynamic> json) {
    return TechnicanMessage(
      en: json['en']?.toString() ?? '',
      ar: json['ar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'en': en,
      'ar': ar,
    };
  }
}

class TechnicanData {
  final List<PropertyStats> propertyStats;
  final String location;
  final String technicianId;

  TechnicanData({
    required this.propertyStats,
    required this.location,
    required this.technicianId,
  });

  factory TechnicanData.fromJson(Map<String, dynamic> json) {
    return TechnicanData(
      propertyStats: json['propertyStats'] != null 
          ? (json['propertyStats'] as List)
              .map((e) => PropertyStats.fromJson(e))
              .toList()
          : [],
      location: json['location']?.toString() ?? '',
      technicianId: json['technician_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyStats': propertyStats.map((e) => e.toJson()).toList(),
      'location': location,
      'technician_id': technicianId,
    };
  }
}

class PropertyStats {
  final String propertyId;
  final String propertyName;
  final String totalComplaints;
  final String unattended;
  final String inProgress;
  final String resolved;
  final String escalatedToMe;
  final String escalatedByMe;

  PropertyStats({
    required this.propertyId,
    required this.propertyName,
    required this.totalComplaints,
    required this.unattended,
    required this.inProgress,
    required this.resolved,
    required this.escalatedToMe,
    required this.escalatedByMe,
  });

  factory PropertyStats.fromJson(Map<String, dynamic> json) {
    return PropertyStats(
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      totalComplaints: json['total_complaints']?.toString() ?? '0',
      unattended: json['unattended']?.toString() ?? '0',
      inProgress: json['in_progress']?.toString() ?? '0',
      resolved: json['resolved']?.toString() ?? '0',
      escalatedToMe: json['escalated_to_me']?.toString() ?? '0',
      escalatedByMe: json['escalated_by_me']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'property_name': propertyName,
      'total_complaints': totalComplaints,
      'unattended': unattended,
      'in_progress': inProgress,
      'resolved': resolved,
      'escalated_to_me': escalatedToMe,
      'escalated_by_me': escalatedByMe,
    };
  }
}