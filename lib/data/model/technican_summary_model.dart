class ComplaintStatisticsResponse {
  final bool success;
  final TechnicanMessage message;
  final TechnicanData data;

  ComplaintStatisticsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ComplaintStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintStatisticsResponse(
      success: json['success'],
      message: TechnicanMessage.fromJson(json['message']),
      data: TechnicanData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message.toJson(),
      'data': data.toJson(),
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
      en: json['en'],
      ar: json['ar'],
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
      propertyStats: (json['propertyStats'] as List)
          .map((e) => PropertyStats.fromJson(e))
          .toList(),
      location: json['location'],
      technicianId: json['technician_id'],
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
      propertyId: json['property_id'],
      propertyName: json['property_name'],
      totalComplaints: json['total_complaints'],
      unattended: json['unattended'],
      inProgress: json['in_progress'],
      resolved: json['resolved'],
      escalatedToMe: json['escalated_to_me'],
      escalatedByMe: json['escalated_by_me'],
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