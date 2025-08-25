// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';

// class LocalizationController extends GetxController {
//   var translations = <String, dynamic>{}.obs; // Observable Map
//   var currentLocale = const Locale('en').obs; // Default English
//   @override
//   void onInit() {
//     super.onInit();
//     loadTranslations(currentLocale.value.languageCode);
//   }

//   Future<void> loadTranslations(String langCode) async {
//     bool success = await fetchFromApi(langCode);
//     if (!success) {
//       bool cached = await loadFromCache(langCode);
//       if (!cached) {
//         await loadFromAssets(langCode);
//       }
//     }

//     // Update current locale
//     currentLocale.value = Locale(langCode);
//   }

//   bool isRTL() {
//     return currentLocale.value.languageCode == 'ar'; // Arabic should be RTL
//   }

//   // Load from assets (Fallback)
//   Future<void> loadFromAssets(String langCode) async {
//     try {
//       String jsonString =
//           await rootBundle.loadString('assets/lang/$langCode.json');
//       Map<String, dynamic> jsonMap = json.decode(jsonString);
//       translations.value =
//           jsonMap.map((key, value) => MapEntry(key, value.toString()));

//       // Save to cache for future use
//       saveToCache(langCode, jsonString);
//     } catch (e) {
//       debugPrint('Error loading from assets: $e');
//     }
//   }

//   // Fetch from API (Future Feature)
//   Future<bool> fetchFromApi(String langCode) async {
//     // String url = 'https://example.com/lang/$langCode.json'; // API endpoint
//     // try {
//     //   final response = await Dio().get(url);
//     //   if (response.statusCode == 200) {
//     //     Map<String, dynamic> jsonMap = response.data;
//     //     translations.value =
//     //         jsonMap.map((key, value) => MapEntry(key, value.toString()));

//     //     // Save API response to cache
//     //     saveToCache(langCode, json.encode(response.data));
//     //     return true;
//     //   }
//     // } catch (e) {
//     //   print('API fetch error: $e');
//     // }
//     return false;
//   }

//   // Load from cache
//   Future<bool> loadFromCache(String langCode) async {
//     var box = GetStorage();
//     String? cachedData = box.read('lang_$langCode');
//     if (cachedData != null) {
//       Map<String, dynamic> jsonMap = json.decode(cachedData);
//       translations.value =
//           jsonMap.map((key, value) => MapEntry(key, value.toString()));
//       return true;
//     }
//     return false;
//   }

//   // Save to cache
//   Future<void> saveToCache(String langCode, String jsonData) async {
//     var box = GetStorage();
//     await box.write('lang_$langCode', jsonData);
//   }

//   // Translate function
//   dynamic translate(String key) {
//     debugPrint('Translating: ${translations[key]}');
//     return translations[key] ?? key; // Fallback to key if not found
//   }

//   // List<dynamic> translateList(String key) {
//   //   try {
//   //     var data = translate(key);

//   //     debugPrint(
//   //         'Raw translation data for key "$key": $data'); // Debugging output

//   //     if (data is List) {
//   //       return data; // Already a List, return directly
//   //     } else if (data is String) {
//   //       return jsonDecode(data); // Decode JSON string into List
//   //     } else {
//   //       throw FormatException("Invalid data format");
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Error decoding JSON for key "$key": $e');
//   //     return []; // Return empty list on error
//   //   }
//   // }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationController extends GetxController {
  var translations =
      <String, dynamic>{}.obs; // Observable Map to hold dynamic values
  var currentLocale = const Locale('en').obs;

  // Fixed getter for isEnglish
  bool get isEnglish => currentLocale.value.languageCode == 'en';
  
  // Added missing isArabic getter
  bool get isArabic => currentLocale.value.languageCode == 'ar';

  @override
  void onInit() {
    super.onInit();
    loadTranslations(currentLocale.value.languageCode);
  }

  Future<void> loadTranslations(String langCode) async {
    bool success = await fetchFromApi(langCode);
    if (!success) {
      bool cached = await loadFromCache(langCode);
      if (!cached) {
        await loadFromAssets(langCode);
      }
    }

    // Update current locale
    currentLocale.value = Locale(langCode);
  }

  bool isRTL() {
    return currentLocale.value.languageCode == 'ar'; // Arabic should be RTL
  }

  // Method to change language
  Future<void> changeLanguage(String langCode) async {
    await loadTranslations(langCode);
    Get.updateLocale(Locale(langCode));
  }

  // Load from assets (Fallback)
  Future<void> loadFromAssets(String langCode) async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/lang/$langCode.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      translations.value = jsonMap.map((key, value) => MapEntry(key, value));

      // Save to cache for future use
      saveToCache(langCode, jsonString);
    } catch (e) {
      debugPrint('Error loading from assets: $e');
    }
  }

  // Fetch from API (Future Feature)
  Future<bool> fetchFromApi(String langCode) async {
    // String url = 'https://example.com/lang/$langCode.json'; // API endpoint
    // try {
    //   final response = await Dio().get(url);
    //   if (response.statusCode == 200) {
    //     Map<String, dynamic> jsonMap = response.data;
    //     translations.value =
    //         jsonMap.map((key, value) => MapEntry(key, value));

    //     // Save API response to cache
    //     saveToCache(langCode, json.encode(response.data));
    //     return true;
    //   }
    // } catch (e) {
    //   print('API fetch error: $e');
    // }
    return false;
  }

  // Load from cache
  Future<bool> loadFromCache(String langCode) async {
    var box = GetStorage();
    String? cachedData = box.read('lang_$langCode');
    if (cachedData != null) {
      Map<String, dynamic> jsonMap = json.decode(cachedData);
      translations.value = jsonMap.map((key, value) => MapEntry(key, value));
      return true;
    }
    return false;
  }

  // Save to cache
  Future<void> saveToCache(String langCode, String jsonData) async {
    var box = GetStorage();
    await box.write('lang_$langCode', jsonData);
  }

  // Get current language name
  String get currentLanguageName {
    switch (currentLocale.value.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  // Translate function (handles strings, lists, and dynamic types)
  dynamic translate(String key) {
    debugPrint('Translating: $key');
    return _getTranslationValue(translations[key], key);
  }

  // Helper function to recursively handle translation of complex values
  dynamic _getTranslationValue(dynamic value, String key) {
    if (value == null) {
      return key; // Fallback to the key if translation is not found
    }

    // If the value is a list, we will return the list of translated values
    if (value is List) {
      return value.map((e) => _getTranslationValue(e, key)).toList();
    }

    // If the value is a Map, we'll iterate over it and translate its values
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, _getTranslationValue(v, key)));
    }

    // If it's a string or another simple type, return it directly
    return value;
  }
}