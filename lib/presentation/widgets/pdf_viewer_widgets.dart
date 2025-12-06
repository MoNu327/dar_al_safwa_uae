import 'package:flutter/material.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:get/get.dart';

/// ✨ BEAUTIFUL PDF VIEWER - Enhanced version with better clarity and UX
class InlinePdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final bool showDownloadButton;
  final VoidCallback? onDownload;

  const InlinePdfViewer({
    Key? key,
    required this.pdfUrl,
    required this.title,
    this.showDownloadButton = true,
    this.onDownload,
  }) : super(key: key);

  @override
  State<InlinePdfViewer> createState() => _InlinePdfViewerState();
}

class _InlinePdfViewerState extends State<InlinePdfViewer> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        width: Get.width,
        height: Get.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ✨ BEAUTIFUL HEADER
              _buildModernHeader(),
              
              // 📄 PDF VIEWER with loading indicator
              Expanded(
                child: Stack(
                  children: [
                    // PDF Viewer
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: SfPdfViewer.network(
                        widget.pdfUrl,
                        controller: _pdfViewerController,
                        enableDoubleTapZooming: true,
                        enableTextSelection: true,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        pageSpacing: 4,
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            _isLoading = false;
                            _totalPages = details.document.pages.count;
                          });
                          debugPrint('✅ PDF loaded successfully: $_totalPages pages');
                        },
                        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                          setState(() {
                            _isLoading = false;
                          });
                          debugPrint('❌ PDF load failed: ${details.error}');
                          debugPrint('   Description: ${details.description}');
                          
                          // Show error message
                          Get.snackbar(
                            'PDF Load Failed',
                            'Could not load the PDF document',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        },
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                        },
                        onZoomLevelChanged: (PdfZoomDetails details) {
                          setState(() {
                            _zoomLevel = details.newZoomLevel;
                          });
                        },
                      ),
                    ),
                    
                    // Loading indicator
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.9),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading PDF...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 🎛️ CONTROL BAR (page navigation + zoom)
              if (!_isLoading && _totalPages > 0) _buildControlBar(),
              
              // ⚡ ACTION BUTTONS
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ MODERN HEADER
  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // PDF Icon with animation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: AppColors.secondaryColor,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_isLoading && _totalPages > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$_totalPages ${_totalPages == 1 ? 'page' : 'pages'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.secondaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎛️ CONTROL BAR (Page Navigation + Zoom)
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Navigation
          Row(
            children: [
              // Previous Page
              IconButton(
                onPressed: _currentPage > 1
                    ? () {
                        _pdfViewerController.previousPage();
                      }
                    : null,
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: _currentPage > 1 ? AppColors.primaryColor : Colors.grey[400],
                ),
                tooltip: 'Previous Page',
              ),
              
              // Page Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              
              // Next Page
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () {
                        _pdfViewerController.nextPage();
                      }
                    : null,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: _currentPage < _totalPages ? AppColors.primaryColor : Colors.grey[400],
                ),
                tooltip: 'Next Page',
              ),
            ],
          ),
          
          // Zoom Controls
          Row(
            children: [
              // Zoom Out
              IconButton(
                onPressed: _zoomLevel > 1.0
                    ? () {
                        _pdfViewerController.zoomLevel = _zoomLevel - 0.25;
                      }
                    : null,
                icon: Icon(
                  Icons.zoom_out,
                  size: 20,
                  color: _zoomLevel > 1.0 ? AppColors.primaryColor : Colors.grey[400],
                ),
                tooltip: 'Zoom Out',
              ),
              
              // Zoom Level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(_zoomLevel * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              
              // Zoom In
              IconButton(
                onPressed: _zoomLevel < 3.0
                    ? () {
                        _pdfViewerController.zoomLevel = _zoomLevel + 0.25;
                      }
                    : null,
                icon: Icon(
                  Icons.zoom_in,
                  size: 20,
                  color: _zoomLevel < 3.0 ? AppColors.primaryColor : Colors.grey[400],
                ),
                tooltip: 'Zoom In',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⚡ ACTION BUTTONS
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Download Button
          if (widget.showDownloadButton && widget.onDownload != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download, size: 20),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ),
          
          if (widget.showDownloadButton && widget.onDownload != null)
            const SizedBox(width: 12),
          
          // Close Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close, size: 20),
              label: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: AppColors.secondaryColor
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}