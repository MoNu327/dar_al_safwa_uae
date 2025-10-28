class TenantDocumentResponse {
  final bool success;
  final String baseUrl;
  final TenantProperty? tenantProperty;
  final Booking? booking;
  final List<BookingDocument> bookingDocuments;
  final List<PaymentDocument> paymentDocuments;
  final DocumentSummary? documentSummary;

  TenantDocumentResponse({
    required this.success,
    required this.baseUrl,
    this.tenantProperty,
    this.booking,
    required this.bookingDocuments,
    required this.paymentDocuments,
    this.documentSummary,
  });

  factory TenantDocumentResponse.fromJson(Map<String, dynamic> json) {
    return TenantDocumentResponse(
      success: json['success'] ?? false,
      baseUrl: json['base_url'] ?? '',
      tenantProperty: json['tenant_property'] != null
          ? TenantProperty.fromJson(json['tenant_property'])
          : null,
      booking:
          json['booking'] != null ? Booking.fromJson(json['booking']) : null,
      bookingDocuments: (json['bookingdocuments'] as List? ?? [])
          .map((e) => BookingDocument.fromJson(e))
          .toList(),
      paymentDocuments: (json['paymentdocuments'] as List? ?? [])
          .map((e) => PaymentDocument.fromJson(e))
          .toList(),
      documentSummary: json['document_summary'] != null
          ? DocumentSummary.fromJson(json['document_summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'base_url': baseUrl,
      'tenant_property': tenantProperty?.toJson(),
      'booking': booking?.toJson(),
      'bookingdocuments': bookingDocuments.map((e) => e.toJson()).toList(),
      'paymentdocuments': paymentDocuments.map((e) => e.toJson()).toList(),
      'document_summary': documentSummary?.toJson(),
    };
  }
}

class TenantProperty {
  final String id;
  final String uid;
  final String propertyId;
  final String unitId;
  final String bookingId;
  final String allocationDate;
  final String startDate;
  final String endDate;
  final String status;
  final String isRenewed;

  TenantProperty({
    required this.id,
    required this.uid,
    required this.propertyId,
    required this.unitId,
    required this.bookingId,
    required this.allocationDate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isRenewed,
  });

  factory TenantProperty.fromJson(Map<String, dynamic> json) {
    return TenantProperty(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      propertyId: json['propertyid'] ?? '',
      unitId: json['unitid'] ?? '',
      bookingId: json['bookingid'] ?? '',
      allocationDate: json['allocation_date'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      isRenewed: json['is_renewed'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'propertyid': propertyId,
      'unitid': unitId,
      'bookingid': bookingId,
      'allocation_date': allocationDate,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'is_renewed': isRenewed,
    };
  }
}

class Booking {
  final String id;
  final String? uid;
  final String firstName;
  final String lastName;
  final String? email;
  final String mobile;

  Booking({
    required this.id,
    this.uid,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.mobile,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      uid: json['uid'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
    };
  }
}

class BookingDocument {
  final String id;
  final String documentTypeCategory;
  final String userBid;
  final String usersBookingId;
  final String? uid;
  final String title;
  final String imageUrl;
  final String documentType;
  final String documentCategory;
  final String documentSubtype;
  final String verificationStatus;
  final String verificationStatusCode;
  final String expiryDate;
  final bool isExpired;
  final String createdAt;
  final String updatedAt;

  BookingDocument({
    required this.id,
    required this.documentTypeCategory,
    required this.userBid,
    required this.usersBookingId,
    this.uid,
    required this.title,
    required this.imageUrl,
    required this.documentType,
    required this.documentCategory,
    required this.documentSubtype,
    required this.verificationStatus,
    required this.verificationStatusCode,
    required this.expiryDate,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingDocument.fromJson(Map<String, dynamic> json) {
    return BookingDocument(
      id: json['id'] ?? '',
      documentTypeCategory: json['document_type_category'] ?? '',
      userBid: json['userbid'] ?? '',
      usersBookingId: json['usersbooking_id'] ?? '',
      uid: json['uid'],
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      documentType: json['document_type'] ?? '',
      documentCategory: json['document_category'] ?? '',
      documentSubtype: json['document_subtype'] ?? '',
      verificationStatus: json['verification_status'] ?? '',
      verificationStatusCode: json['verification_status_code'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      isExpired: json['is_expired'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type_category': documentTypeCategory,
      'userbid': userBid,
      'usersbooking_id': usersBookingId,
      'uid': uid,
      'title': title,
      'image_url': imageUrl,
      'document_type': documentType,
      'document_category': documentCategory,
      'document_subtype': documentSubtype,
      'verification_status': verificationStatus,
      'verification_status_code': verificationStatusCode,
      'expiry_date': expiryDate,
      'is_expired': isExpired,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class PaymentDocument {
  final String id;
  final String documentTypeCategory;
  final String confirmationId;
  final String segmentId;
  final String title;
  final String imageUrl;
  final String documentType;
  final String documentCategory;
  final String documentSubtype;
  final String verificationStatus;
  final String verificationStatusCode;
  final String expiryDate;
  final bool isExpired;
  final String createdAt;
  final String updatedAt;
  final PaymentDetails? paymentDetails;

  PaymentDocument({
    required this.id,
    required this.documentTypeCategory,
    required this.confirmationId,
    required this.segmentId,
    required this.title,
    required this.imageUrl,
    required this.documentType,
    required this.documentCategory,
    required this.documentSubtype,
    required this.verificationStatus,
    required this.verificationStatusCode,
    required this.expiryDate,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
    this.paymentDetails,
  });

  factory PaymentDocument.fromJson(Map<String, dynamic> json) {
    return PaymentDocument(
      id: json['id'] ?? '',
      documentTypeCategory: json['document_type_category'] ?? '',
      confirmationId: json['confirmation_id'] ?? '',
      segmentId: json['segment_id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      documentType: json['document_type'] ?? '',
      documentCategory: json['document_category'] ?? '',
      documentSubtype: json['document_subtype'] ?? '',
      verificationStatus: json['verification_status'] ?? '',
      verificationStatusCode: json['verification_status_code'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      isExpired: json['is_expired'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      paymentDetails: json['payment_details'] != null
          ? PaymentDetails.fromJson(json['payment_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type_category': documentTypeCategory,
      'confirmation_id': confirmationId,
      'segment_id': segmentId,
      'title': title,
      'image_url': imageUrl,
      'document_type': documentType,
      'document_category': documentCategory,
      'document_subtype': documentSubtype,
      'verification_status': verificationStatus,
      'verification_status_code': verificationStatusCode,
      'expiry_date': expiryDate,
      'is_expired': isExpired,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'payment_details': paymentDetails?.toJson(),
    };
  }
}

class PaymentDetails {
  final String paymentMethod;
  final String installmentNumber;
  final String amount;
  final String chequeNumber;
  final String chequeDate;
  final String chequeBankName;
  final String? transactionReference;
  final String? receiptNumber;
  final AllImages allImages;

  PaymentDetails({
    required this.paymentMethod,
    required this.installmentNumber,
    required this.amount,
    required this.chequeNumber,
    required this.chequeDate,
    required this.chequeBankName,
    this.transactionReference,
    this.receiptNumber,
    required this.allImages,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      paymentMethod: json['payment_method'] ?? '',
      installmentNumber: json['installment_number'] ?? '',
      amount: json['amount'] ?? '',
      chequeNumber: json['cheque_number'] ?? '',
      chequeDate: json['cheque_date'] ?? '',
      chequeBankName: json['cheque_bank_name'] ?? '',
      transactionReference: json['transaction_reference'],
      receiptNumber: json['receipt_number'],
      allImages: AllImages.fromJson(json['all_images'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'installment_number': installmentNumber,
      'amount': amount,
      'cheque_number': chequeNumber,
      'cheque_date': chequeDate,
      'cheque_bank_name': chequeBankName,
      'transaction_reference': transactionReference,
      'receipt_number': receiptNumber,
      'all_images': allImages.toJson(),
    };
  }
}

class AllImages {
  final String? chequeImage;
  final String? transferProof;
  final String? receiptImage;
  final String? paymentImage;

  AllImages({
    this.chequeImage,
    this.transferProof,
    this.receiptImage,
    this.paymentImage,
  });

  factory AllImages.fromJson(Map<String, dynamic> json) {
    return AllImages(
      chequeImage: json['cheque_image'],
      transferProof: json['transfer_proof'],
      receiptImage: json['receipt_image'],
      paymentImage: json['payment_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cheque_image': chequeImage,
      'transfer_proof': transferProof,
      'receipt_image': receiptImage,
      'payment_image': paymentImage,
    };
  }
}

class DocumentSummary {
  final int totalDocuments;
  final int bookingDocumentsCount;
  final int paymentDocumentsCount;

  DocumentSummary({
    required this.totalDocuments,
    required this.bookingDocumentsCount,
    required this.paymentDocumentsCount,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) {
    return DocumentSummary(
      totalDocuments: json['total_documents'] ?? 0,
      bookingDocumentsCount: json['booking_documents_count'] ?? 0,
      paymentDocumentsCount: json['payment_documents_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_documents': totalDocuments,
      'booking_documents_count': bookingDocumentsCount,
      'payment_documents_count': paymentDocumentsCount,
    };
  }
}
