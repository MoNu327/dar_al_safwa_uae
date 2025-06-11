import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AgentRegisteredPropertyController extends GetxController {
  final agentProperties = <Map<String, dynamic>>[].obs;
  final selectedCurrency = 'OMR'.obs;
  final selectedStatus = 'Available'.obs;

  final List<String> currencies = [
    'OMR',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'SAR',
    'QAR',
    'KWD',
    'BHD'
  ];

  void updateCurrency(String? value) {
    if (value != null) selectedCurrency.value = value;
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    loadAgentProperties();
  }

  void loadAgentProperties() {
    final properties = [
      {
        'id': 1,
        'imageUrl':
            'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400',
        'propertyName': 'Luxury Villa in Al Mouj',
        'status': 'For sale',
        'location': 'Al Mouj, Muscat',
        'price': '450,000 KWD',
        'area': '3,200 sq.ft',
        'bedrooms': 5,
        'bathrooms': 4,
        'listedDate': '2023-01-10',
        'description': 'Spacious luxury villa with private pool and garden',
      },
      {
        'id': 2,
        'imageUrl':
            'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=400',
        'propertyName': 'Modern Apartment in Qurm',
        'status': 'Sold out',
        'location': 'Qurm, Muscat',
        'price': '380,000 KWD',
        'area': '2,100 sq.ft',
        'bedrooms': 3,
        'bathrooms': 2,
        'listedDate': '2022-11-15',
        'soldDate': '2023-03-20',
        'description': 'Modern apartment with sea view and premium finishes',
      },
      {
        'id': 3,
        'imageUrl':
            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
        'propertyName': 'Commercial Space in CBD Muscat',
        'status': 'For sale',
        'location': 'Muscat, Central Business District',
        'price': '620,000 KWD',
        'area': '5,500 sq.ft',
        'listedDate': '2023-02-05',
        'description': 'Prime commercial space ideal for offices or retail',
      },
      {
        'id': 4,
        'imageUrl':
            'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=400',
        'propertyName': 'Penthouse in Shatti Al Qurum',
        'status': 'For sale',
        'location': 'Shatti Al Qurum, Muscat',
        'price': '750,000 KWD',
        'area': '4,800 sq.ft',
        'bedrooms': 4,
        'bathrooms': 3,
        'listedDate': '2023-03-18',
        'description': 'Luxury penthouse with panoramic sea views',
      },
    ];

    agentProperties.assignAll(properties);
  }

  /// Returns the appropriate color based on property status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'for sale':
      case 'available':
        return AppColors.onlineGreen;
      case 'sold out':
      case 'sold':
        return AppColors.redColor;
      case 'under list':
      case 'under listing':
      case 'pending':
        return AppColors.warning;
      case 'rented':
      case 'for rent':
        return AppColors.blueColor;
      case 'reserved':
      case 'on hold':
        return AppColors.secondaryColor;
      default:
        return AppColors.lightGrey;
    }
  }

  /// Returns the background color with opacity for status badges
  Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  /// Returns formatted status text (capitalize first letter)
  String getFormattedStatus(String status) {
    return status
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }
}
