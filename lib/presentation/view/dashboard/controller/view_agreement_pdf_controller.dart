import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class ViewAgreementController extends GetxController {
  RxString pdfPath = ''.obs;
  RxBool isLoading = false.obs;
  void onInit() {
    super.onInit(); // Don't forget to call super.onInit()
    loadPdfFromAssets();
  }

  Future<void> loadPdfFromAssets() async {
    try {
      isLoading(true);

      // Load PDF from assets
      final ByteData data = await rootBundle.load('assets/pdf/Agreement.pdf');
      final bytes = data.buffer.asUint8List();

      // Save to temporary file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Agreement.pdf');
      await file.writeAsBytes(bytes);

      pdfPath(file.path);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load PDF: $e');
    } finally {
      isLoading(false);
    }
  }
}
