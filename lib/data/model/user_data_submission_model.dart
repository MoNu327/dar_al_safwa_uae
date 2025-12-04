import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserDataSubmissionModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String address;
  final String email;
  final String mobile;
  final String propertyId;
  final String unitId;
  final bool citizenship;
  final List<AdditionalDocument> additionalDocuments;
  final String? rentalPref; // <-- New optional field

  UserDataSubmissionModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.email,
    required this.mobile,
    required this.propertyId,
    required this.unitId,
    required this.citizenship,
    required this.additionalDocuments,
    this.rentalPref, // <-- optional
  });

  factory UserDataSubmissionModel.fromMap(Map<String, dynamic> data) {
    List<AdditionalDocument> documents = [];

    Map<int, Map<String, dynamic>> docMap = {};

    data.forEach((key, value) {
      if (key.startsWith('additional_document_titles[')) {
        final index = int.parse(key.replaceAll(RegExp(r'[^0-9]'), ''));
        docMap[index] ??= {};
        docMap[index]!['title'] = value;
      } else if (key.startsWith('additional_document_expiry_dates[')) {
        final index = int.parse(key.replaceAll(RegExp(r'[^0-9]'), ''));
        docMap[index] ??= {};
        docMap[index]!['expiryDate'] = value;
      } else if (key.startsWith('additional_documents[')) {
        final index = int.parse(key.replaceAll(RegExp(r'[^0-9]'), ''));
        docMap[index] ??= {};
        docMap[index]!['file'] = value;
      }
    });

    docMap.forEach((index, docData) {
      documents.add(AdditionalDocument(
        title: docData['title'] ?? '',
        expiryDate: DateTime.parse(docData['expiryDate']),
        file: docData['file'],
      ));
    });

    return UserDataSubmissionModel(
      uid: data['uid'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      propertyId: data['propertyid'] ?? '',
      unitId: data['unitid'] ?? '',
      citizenship: data['citizenship'] == '1',
      additionalDocuments: documents,
      rentalPref: data['rentalpref'], // <-- added
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'email': email,
      'mobile': mobile,
      'propertyid': propertyId,
      'unitid': unitId,
      'citizenship': citizenship ? '1' : '0',
    };

    if (rentalPref != null) {
      map['rentalpref'] = rentalPref; // <-- added
    }

    for (var i = 0; i < additionalDocuments.length; i++) {
      final doc = additionalDocuments[i];
      map['additional_document_titles[$i]'] = doc.title;
      map['additional_document_expiry_dates[$i]'] =
          doc.expiryDate.toIso8601String().split('T')[0];
      if (doc.file != null) {
        map['additional_documents[$i]'] = doc.file;
      }
    }

    return map;
  }

  Future<Map<String, dynamic>> toFormData() async {
    final formData = <String, dynamic>{
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'email': email,
      'mobile': mobile,
      'propertyid': propertyId,
      'unitid': unitId,
      'citizenship': citizenship ? '1' : '0',
    };

    if (rentalPref != null) {
      formData['rentalpref'] = rentalPref; // <-- added
    }

    for (var i = 0; i < additionalDocuments.length; i++) {
      final doc = additionalDocuments[i];
      formData['additional_document_titles[$i]'] = doc.title;
      formData['additional_document_expiry_dates[$i]'] =
          doc.expiryDate.toIso8601String().split('T')[0];

      if (doc.file != null) {
        if (doc.file is File) {
          formData['additional_documents[$i]'] =
              await http.MultipartFile.fromPath(
            'additional_documents[$i]',
            doc.file.path,
            filename:
                'document_${i}_${doc.title.replaceAll(' ', '_')}.${doc.file.path.split('.').last}',
          );
        } else if (doc.file is Uint8List) {
          formData['additional_documents[$i]'] =
              http.MultipartFile.fromBytes(
            'additional_documents[$i]',
            doc.file,
            filename:
                'document_${i}_${doc.title.replaceAll(' ', '_')}.pdf',
          );
        } else {
          formData['additional_documents[$i]'] = doc.file;
        }
      }
    }

    return formData;
  }

  UserDataSubmissionModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? address,
    String? email,
    String? mobile,
    String? propertyId,
    String? unitId,
    bool? citizenship,
    List<AdditionalDocument>? additionalDocuments,
    String? rentalPref, // <-- added
  }) {
    return UserDataSubmissionModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      citizenship: citizenship ?? this.citizenship,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
      rentalPref: rentalPref ?? this.rentalPref, // <-- added
    );
  }
}

class AdditionalDocument {
  final String title;
  final DateTime expiryDate;
  final dynamic file;

  AdditionalDocument({
    required this.title,
    required this.expiryDate,
    this.file,
  });

  AdditionalDocument copyWith({
    String? title,
    DateTime? expiryDate,
    dynamic file,
  }) {
    return AdditionalDocument(
      title: title ?? this.title,
      expiryDate: expiryDate ?? this.expiryDate,
      file: file ?? this.file,
    );
  }
}
