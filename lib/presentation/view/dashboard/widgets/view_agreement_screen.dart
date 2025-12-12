import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../controller/view_agreement_pdf_controller.dart';

class PdfViewerScreen extends StatefulWidget {
  final String uid;
  final String unitAddressId;

  PdfViewerScreen({
    required this.uid,
    required this.unitAddressId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool isPdfLoading = true;
  String? localPdfPath;
  double downloadProgress = 0.0;
  String statusMessage = "Preparing...";
  String? pdfUrl;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Fetch agreement when screen loads
    final controller = Get.put(ViewAgreementController());
    controller.fetchAgreement(widget.uid, widget.unitAddressId);
  }

  // Generate a unique filename based on URL to avoid conflicts
  String _generateCacheFileName(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    return 'pdf_cache_$hash.pdf';
  }

  Future<void> downloadAndCachePdf(String url) async {
    if (!mounted) return;
    
    try {
      setState(() {
        statusMessage = "Checking cache...";
        downloadProgress = 0.0;
      });

      // Use APPLICATION DOCUMENTS directory for permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/pdf_cache');
      
      // Create cache directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = _generateCacheFileName(url);
      final file = File('${cacheDir.path}/$fileName');

      // Check if already cached
      if (await file.exists()) {
        print("✅ PDF found in permanent cache: ${file.path}");
        if (mounted) {
          setState(() {
            localPdfPath = file.path;
            isPdfLoading = false;
            statusMessage = "Loaded from cache";
          });
        }
        return;
      }

      print("📥 PDF not in cache, downloading from: $url");

      if (mounted) {
        setState(() {
          statusMessage = "Downloading PDF...";
        });
      }

      // Download with progress
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int downloadedBytes = 0;
        List<int> bytes = [];

        await for (var chunk in response.stream) {
          bytes.addAll(chunk);
          downloadedBytes += chunk.length;

          if (contentLength > 0 && mounted) {
            setState(() {
              downloadProgress = downloadedBytes / contentLength;
              statusMessage = "Downloading... ${(downloadProgress * 100).toInt()}%";
            });
          }
        }

        // Save to permanent cache
        await file.writeAsBytes(bytes);
        print("✅ PDF saved to permanent cache: ${file.path}");

        if (mounted) {
          setState(() {
            localPdfPath = file.path;
            isPdfLoading = false;
            statusMessage = "Download complete";
          });
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error downloading PDF: $e");
      if (mounted) {
        setState(() {
          isPdfLoading = false;
          statusMessage = "Failed to load PDF";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                if (pdfUrl != null) {
                  setState(() {
                    isPdfLoading = true;
                    isInitialized = false;
                  });
                  downloadAndCachePdf(pdfUrl!);
                }
              },
            ),
          ),
        );
      }
    }
  }

  // Optional: Method to clear cache if needed
  Future<void> clearPdfCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/pdf_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print("🗑️ PDF cache cleared");
      }
    } catch (e) {
      print("❌ Error clearing cache: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ViewAgreementController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading agreement..."),
              ],
            ),
          );
        }

        if (controller.hasError.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Error Loading PDF",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Go Back"),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.agreementList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("No agreement data found."),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Go Back"),
                ),
              ],
            ),
          );
        }

        final agreement = controller.agreementList.first;
        final currentPdfUrl = agreement.pdf_url;

        print("📄 PDF URL: $currentPdfUrl");

        if (currentPdfUrl.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link_off, size: 60, color: Colors.orange),
                const SizedBox(height: 16),
                const Text("PDF URL not available."),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Go Back"),
                ),
              ],
            ),
          );
        }

        // Start download AFTER build is complete
        if (!isInitialized) {
          isInitialized = true;
          pdfUrl = currentPdfUrl;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            downloadAndCachePdf(currentPdfUrl);
          });
        }

        // Show PDF or loading
        return Stack(
          children: [
            // PDF Viewer (only show when loaded)
            if (localPdfPath != null)
              SfPdfViewer.file(
                File(localPdfPath!),
                enableDoubleTapZooming: true,
                canShowScrollHead: false,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                onDocumentLoaded: (details) {
                  print("✅ PDF rendered - Pages: ${details.document.pages.count}");
                },
              ),
            
            // Loading overlay with progress
            if (isPdfLoading)
              Container(
                color: AppColors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: downloadProgress > 0 ? downloadProgress : null,
                                strokeWidth: 6,
                              ),
                            ),
                            if (downloadProgress > 0)
                              Text(
                                "${(downloadProgress * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (statusMessage != "Checking cache...")
                        Text(
                          statusMessage == "Loaded from cache" 
                              ? "Loaded instantly from cache!"
                              : "Please wait...",
                          style: TextStyle(
                            fontSize: 14,
                            color: statusMessage == "Loaded from cache"
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(25),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}