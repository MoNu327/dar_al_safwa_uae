class Validator {
  // ✅ UPDATED: Now supports both English and Arabic characters
  static String? validateName(String? value, {String fieldName = "Name"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    
    // Allow English letters (a-z, A-Z), Arabic letters (\u0600-\u06FF), spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s'\-]+$");
    
    if (!nameRegex.hasMatch(value.trim())) {
      return "$fieldName can only contain letters";
    }
    
    if (value.trim().length < 2) {
      return "$fieldName must be at least 2 characters";
    }
    
    return null;
  }

  // ✅ UPDATED: Now supports both English and Arabic characters
  static String? validateLastname(String? value, {String fieldName = "This field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    
    // Allow English letters, Arabic letters, spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s'\-]+$");
    
    if (!nameRegex.hasMatch(value.trim())) {
      return "$fieldName can only contain letters";
    }
    
    if (value.trim().length < 2) {
      return "$fieldName must be at least 2 characters";
    }
    
    return null;
  }

  // ✅ UPDATED: Now supports Arabic addresses
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Address is required";
    }
    
    // Allow English, Arabic, numbers, spaces, and common address characters (,.-/#)
    final addressRegex = RegExp(r"^[a-zA-Z0-9\u0600-\u06FF\s,.\-/#']+$");
    
    if (!addressRegex.hasMatch(value.trim())) {
      return "Please enter a valid address";
    }
    
    if (value.trim().length < 5) {
      return "Enter a valid address (min 5 characters)";
    }
    
    return null;
  }

  // ✅ UPDATED: Now supports Arabic nationality names
  static String? validateNationality(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Nationality is required";
    }
    
    // Allow English and Arabic letters
    final nationalityRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$");
    
    if (!nationalityRegex.hasMatch(value.trim())) {
      return "Nationality can only contain letters";
    }
    
    if (value.trim().length < 3) {
      return "Enter a valid nationality (min 3 characters)";
    }
    
    return null;
  }

  // ✅ Your existing mobile validation with country code
  static String? validateMobileWithCountryCode(String? value, {required String countryCode}) {
    if (value == null || value.trim().isEmpty) {
      return "Mobile number is required";
    }
    
    // Remove any spaces or special characters
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Different validation based on country code
    switch (countryCode) {
      case '+968': // Oman
        final mobileRegex = RegExp(r"^[789][0-9]{7}$");
        if (!mobileRegex.hasMatch(cleanedValue)) {
          return "Enter a valid 8-digit Omani number starting with 7, 8, or 9";
        }
        break;
        
      case '+971': // UAE
        final mobileRegex = RegExp(r"^5[0-9]{8}$");
        if (!mobileRegex.hasMatch(cleanedValue)) {
          return "Enter a valid 9-digit UAE number starting with 5";
        }
        break;
        
      default:
        // Generic validation for other countries
        if (cleanedValue.length < 8 || cleanedValue.length > 15) {
          return "Enter a valid mobile number";
        }
    }
    
    return null;
  }

  // ✅ Your existing UAE mobile validation
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Mobile number is required";
    }

    // Remove any spaces or special characters
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    // UAE mobile numbers: 9 digits starting with 5
    final mobileRegex = RegExp(r"^5[0-9]{8}$");

    if (!mobileRegex.hasMatch(cleanedValue)) {
      return "Enter a valid 9-digit UAE mobile number starting with 5";
    }

    return null;
  }

  // ✅ Your existing email validation (unchanged)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  // ✅ Your existing PO number validation (unchanged)
  static String? validatePoNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "PO Number is required";
    } else if (value.trim().length < 3) {
      return "Enter a valid PO Number";
    }
    return null;
  }

  // ✅ Your existing passport validation (unchanged)
  static String? validatePassport(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Passport number is required";
    }
    if (value.trim().length < 6) {
      return "Enter a valid passport number";
    }
    return null;
  }

  // ✅ Your existing visa validation (unchanged)
  static String? validateVisa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Visa number is required";
    }
    return null;
  }
}