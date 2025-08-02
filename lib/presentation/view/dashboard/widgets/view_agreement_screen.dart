import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';

import '../../../widgets/custom_appbar_widget.dart';
import '../../../widgets/custom_text_widget.dart';
import '../controller/view_agreement_pdf_controller.dart';

class PdfViewerScreen extends StatelessWidget {
  final ViewAgreementController viewAgreementPdfController =
      Get.put(ViewAgreementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: "View Agreement",
        titleFontSize: appBarTitles,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              if (viewAgreementPdfController.isLoading.value) {
                return const CupertinoActivityIndicator();
              } else if (viewAgreementPdfController.pdfPath.isNotEmpty) {
                return Expanded(
                  child: PDFView(
                    filePath: viewAgreementPdfController.pdfPath.value,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    onError: (error) => Get.snackbar('Error', error.toString()),
                  ),
                );
              } else {
                return const CustomTextWidget(title: 'No PDF loaded!');
              }
            }),
          ],
        ),
      ),
    );
  }
}
