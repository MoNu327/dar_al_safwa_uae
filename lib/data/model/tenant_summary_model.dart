class PropertyStats {
  final String propertyId;
  final String propertyName;
  final String totalComplaints;
  final String startedWorking;
  final String inProgress;
  final String resolved;

  PropertyStats({
    required this.propertyId,
    required this.propertyName,
    required this.totalComplaints,
    required this.startedWorking,
    required this.inProgress,
    required this.resolved,
  });

  factory PropertyStats.fromJson(Map<String, dynamic> json) {
    return PropertyStats(
      propertyId: json['property_id'].toString(), // Convert to string
      propertyName: json['property_name'] ?? '',
      totalComplaints: json['total_complaints'].toString(),
      startedWorking: json['started_working'].toString(),
      inProgress: json['in_progress'].toString(),
      resolved: json['resolved'].toString(),
    );
  }
}

class TenantSummary {
  final List<PropertyStats> propertyStats;
  final String location;
  final String userId;

  TenantSummary({
    required this.propertyStats,
    required this.location,
    required this.userId,
  });

  factory TenantSummary.fromJson(Map<String, dynamic> json) {
    // Access the 'data' object first
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return TenantSummary(
      propertyStats: (data['propertyStats'] as List?)
              ?.map((item) => PropertyStats.fromJson(item))
              .toList() ??
          [],
      location: data['location']?.toString() ?? '0', // Convert to string
      userId: data['user_id']?.toString() ?? '',
    );
  }
}