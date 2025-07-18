class TenantPropertyModel {
  final int id;
  final String propertyTitle;
  final String cityName;
  final String stateName;
  final String unitTypeName;
  final String unitAreaFormatted;
  final String rentAmount;
  final String startDateFormatted;
  final String endDateFormatted;
  final String allocationDateFormatted;
  final String expiryStatus;
  final String addressFormat;
  final String unitNumber;
  final String propertyImageUrl;

  TenantPropertyModel({
    required this.id,
    required this.propertyTitle,
    required this.cityName,
    required this.stateName,
    required this.unitTypeName,
    required this.unitAreaFormatted,
    required this.rentAmount,
    required this.startDateFormatted,
    required this.endDateFormatted,
    required this.allocationDateFormatted,
    required this.expiryStatus,
    required this.addressFormat,
    required this.unitNumber,
    required this.propertyImageUrl,
  });

  factory TenantPropertyModel.fromJson(Map<String, dynamic> json) {
    return TenantPropertyModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      propertyTitle: json['property_title'] ?? '',
      cityName: json['city_name'] ?? '',
      stateName: json['state_name'] ?? '',
      unitTypeName: json['unit_type_name'] ?? '',
      unitAreaFormatted: json['unit_area_formatted'] ?? 'N/A',
      rentAmount: json['rent_amount'] ?? 'N/A',
      startDateFormatted: json['start_date_formatted'] ?? 'N/A',
      endDateFormatted: json['end_date_formatted'] ?? 'N/A',
      allocationDateFormatted: json['allocation_date_formatted'] ?? 'N/A',
      expiryStatus: json['expiry_status'] ?? 'N/A',
      addressFormat: json['AddressFormat'] ?? '',
      unitNumber: json['UnitNumber'] ?? '',
      propertyImageUrl: json['property_image_url'] ?? '',
    );
  }

  static List<TenantPropertyModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => TenantPropertyModel.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_title': propertyTitle,
      'city_name': cityName,
      'state_name': stateName,
      'unit_type_name': unitTypeName,
      'unit_area_formatted': unitAreaFormatted,
      'rent_amount': rentAmount,
      'start_date_formatted': startDateFormatted,
      'end_date_formatted': endDateFormatted,
      'allocation_date_formatted': allocationDateFormatted,
      'expiry_status': expiryStatus,
      'AddressFormat': addressFormat,
      'UnitNumber': unitNumber,
      'property_image_url': propertyImageUrl,
    };
  }
}
