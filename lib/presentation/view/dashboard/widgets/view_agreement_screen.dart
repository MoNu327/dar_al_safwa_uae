import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/view_agreement_pdf_controller.dart';

class PdfViewerScreen extends StatelessWidget {
  final String uid;

  PdfViewerScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ViewAgreementController());

    // Fetch agreement data
    controller.fetchAgreement(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lease Agreement"),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError.value) {
          return Center(
            child: Text(
              "❌ ${controller.errorMessage.value}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (controller.agreementList.isEmpty) {
          return const Center(child: Text("No agreement data found."));
        }

        final agreement = controller.agreementList.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------- HEADER --------------------
              Center(
                child: Column(
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo/launcher.jpg', // Replace with your logo asset
                      height: 80,
                    ),
                    const SizedBox(height: 12),

                    // Company Name
                    const Text(
                      "Majan Real Estate",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Address
                    const Text(
                      "PO Box No. 4224, Mirbah, Fujairah – U.A.E.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),

                    // Contact Info
                    const Text(
                      "Mobile: +971 501924044  |  Tel: +971 92232954  |  Fax: +971 92232872",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    // Divider
                    const Divider(thickness: 1.5, height: 20, color: Colors.grey),

                    // Date
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        agreement.created_at_formatted, // formatted date
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------------------- LEASE AGREEMENT BODY --------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tenant Info
                  Text(
                    agreement.user_display_name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "${agreement.unit_type_title} - ${agreement.unit_number}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    agreement.property_title,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Agreement Title
                  const Text(
                    "Lease Agreement",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Greeting
                  Text(
                    "Dear ${agreement.user_display_name},",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Agreement Body
                  Text(
                    agreement.notification_body,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Signature Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: const [
                          Text("Tenant"),
                          SizedBox(height: 60),
                          Text("___________________"),
                        ],
                      ),
                      Column(
                        children: const [
                          Text("Authorized Signatory"),
                          SizedBox(height: 60),
                          Text("___________________"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Footer Note
                  const Center(
                    child: Text(
                      "This is an official communication. Please retain for your records.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
