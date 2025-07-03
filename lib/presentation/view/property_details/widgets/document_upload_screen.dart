import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String screenTitle;
  final List<DocumentField> documentFields;

  const DocumentUploadScreen({
    super.key,
    required this.screenTitle,
    required this.documentFields,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final Map<int, List<String>> _uploadedFiles = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(Icons.arrow_back),
            color: AppColors.white,
          ),
          backgroundColor: AppColors.secondaryColor,
          title: CustomTextWidget(
            color: AppColors.white,
            title: widget.screenTitle,
            fontSize: appBarTitles,
            overflow: TextOverflow.ellipsis,
          )),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth5,
          vertical: screenHeight2,
        ),
        child: Column(
          // spacing: screenHeight * 0.1,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomTextWidget(
              title: "Upload Required Documents *",
              fontSize: tagTitle,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              overflow: TextOverflow.ellipsis,
            ),
            kHeight(0.02),
            ...widget.documentFields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return _buildDocumentField(index, field);
            }),
            kHeight(0.05),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentField(int index, DocumentField field) {
    final uploadedFiles = _uploadedFiles[index] ?? [];
    final canUploadMore = uploadedFiles.length < field.maxFiles;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight3),
      padding: EdgeInsets.all(screenWidth3),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.title,
            style: TextStyle(
              fontSize: packageTitle,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          if (field.description.isNotEmpty) ...[
            kHeight(0.01),
            Text(
              field.description,
              style: TextStyle(
                fontSize: detailContentTitle,
                color: AppColors.black600,
              ),
            ),
          ],
          kHeight(0.02),
          if (uploadedFiles.isNotEmpty) ...[
            ...uploadedFiles
                .map((filePath) => _buildUploadedFileItem(filePath)),
            kHeight(0.02),
          ],
          if (canUploadMore)
            _buildUploadButton(
              index: index,
              field: field,
              isFirstUpload: uploadedFiles.isEmpty,
            ),
          if (field.maxFiles > 1 && uploadedFiles.isNotEmpty && canUploadMore)
            Text(
              'You can upload ${field.maxFiles - uploadedFiles.length} more ${field.maxFiles - uploadedFiles.length == 1 ? 'file' : 'files'}',
              style: TextStyle(
                fontSize: expandedContentTitle,
                color: AppColors.black500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem(String filePath) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight1),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth2,
        vertical: screenHeight1,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            size: iconSize,
            color: AppColors.secondaryColor,
          ),
          kWidth(0.02),
          Expanded(
            child: Text(
              filePath.split('/').last,
              style: TextStyle(
                fontSize: detailContentTitle,
                color: AppColors.black,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: smallIconSize),
            onPressed: () {
              // Find and remove the file from the uploaded files map
              setState(() {
                _uploadedFiles.forEach((key, value) {
                  if (value.contains(filePath)) {
                    value.remove(filePath);
                    if (value.isEmpty) {
                      _uploadedFiles.remove(key);
                    }
                  }
                });
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required int index,
    required DocumentField field,
    required bool isFirstUpload,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isFirstUpload
            ? AppColors.secondaryColor.withOpacity(0.1)
            : AppColors.white,
        side: BorderSide(
          color: isFirstUpload
              ? AppColors.secondaryColor
              : AppColors.black.withOpacity(0.2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth3,
          vertical: screenHeight1,
        ),
      ),
      onPressed: () => _handleFileUpload(index, field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload,
            size: iconSize,
            color: isFirstUpload
                ? AppColors.secondaryColor
                : AppColors.black.withOpacity(0.6),
          ),
          kWidth(0.02),
          Text(
            isFirstUpload ? 'Upload ${field.title}' : 'Add Another',
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: detailContentTitle,
              color: isFirstUpload
                  ? AppColors.secondaryColor
                  : AppColors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allFieldsFilled = widget.documentFields.every((field) {
      final index = widget.documentFields.indexOf(field);
      return _uploadedFiles.containsKey(index) &&
          _uploadedFiles[index]!.isNotEmpty;
    });

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: allFieldsFilled
              ? AppColors.secondaryColor
              : AppColors.secondaryColor.withOpacity(0.5),
          padding: EdgeInsets.symmetric(vertical: screenHeight2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: allFieldsFilled ? _submitDocuments : null,
        child: Text(
          'Submit Documents',
          style: TextStyle(
            fontSize: packageTitle,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFileUpload(int index, DocumentField field) async {
    // In a real app, you would implement file picking here
    // For demonstration, we'll simulate a file picker

    // Simulate file picking delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Generate a fake file path for demonstration
    final fakeFilePath =
        'path/to/${field.title.toLowerCase().replaceAll(' ', '')}${_uploadedFiles[index]?.length ?? 0}.${field.allowedTypes == FileType.image ? 'jpg' : 'pdf'}';

    setState(() {
      _uploadedFiles.putIfAbsent(index, () => []).add(fakeFilePath);
    });
  }

  void _submitDocuments() {
    // Process the uploaded files
    final allFiles = <String, List<String>>{};
    for (var entry in _uploadedFiles.entries) {
      final fieldIndex = entry.key;
      final files = entry.value;
      final fieldTitle = widget.documentFields[fieldIndex].title;
      allFiles[fieldTitle] = files;
    }

    // In a real app, you would upload these files to your backend
    Get.snackbar(
      'Documents Submitted',
      '${allFiles.values.fold<int>(0, (sum, files) => sum + files.length)} files uploaded successfully',
      backgroundColor: AppColors.onlineGreen,
      colorText: AppColors.white,
    );

    // For demo, just print the files
    debugPrint('Submitted files: $allFiles');
  }
}

class DocumentField {
  final String title;
  final String description;
  final int maxFiles;
  final FileType allowedTypes;

  const DocumentField({
    required this.title,
    this.description = '',
    this.maxFiles = 1,
    this.allowedTypes = FileType.any,
  });
}

enum FileType {
  image,
  pdf,
  any,
}
