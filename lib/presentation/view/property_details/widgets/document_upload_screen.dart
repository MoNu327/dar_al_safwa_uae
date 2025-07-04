import 'package:dar_al_safwa/presentation/view_model/firebase_auth_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/model/document_submission_model.dart';
import '../controller/user_data_submission_controller.dart';

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
  final Map<int, List<File>> _uploadedFiles = {};
  bool _isSubmitting = false;
  final controler = Get.find<UserDataSubmissionController>();
  final user = Get.put(AuthService());

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
            ...uploadedFiles.map((file) => _buildUploadedFileItem(file, index)),
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

  Widget _buildUploadedFileItem(File file, int fieldIndex) {
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
              file.path.split('/').last,
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
              setState(() {
                _uploadedFiles[fieldIndex]?.remove(file);
                if (_uploadedFiles[fieldIndex]?.isEmpty ?? false) {
                  _uploadedFiles.remove(fieldIndex);
                }
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
          backgroundColor: allFieldsFilled && !_isSubmitting
              ? AppColors.secondaryColor
              : AppColors.secondaryColor.withOpacity(0.5),
          padding: EdgeInsets.symmetric(vertical: screenHeight2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: allFieldsFilled && !_isSubmitting ? _submitDocuments : null,
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
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
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, //widget.documentFields[index].allowedTypes.
        allowedExtensions: _getAllowedExtensions(field.allowedTypes),
        allowMultiple: field.maxFiles > 1,
      );

      if (result != null) {
        final files = result.paths.map((path) => File(path!)).toList();

        setState(() {
          if (_uploadedFiles.containsKey(index)) {
            // Add to existing files, respecting maxFiles limit
            final currentFiles = _uploadedFiles[index]!;
            final remainingSlots = field.maxFiles - currentFiles.length;
            final filesToAdd = files.take(remainingSlots).toList();
            _uploadedFiles[index]!.addAll(filesToAdd);
          } else {
            // First upload for this field
            _uploadedFiles[index] = files.take(field.maxFiles).toList();
          }
        });

        if (files.length > field.maxFiles) {
          Get.snackbar(
            'Upload Limit',
            'Only ${field.maxFiles} files can be uploaded for ${field.title}',
            backgroundColor: AppColors.warning,
            colorText: AppColors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload file: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    }
  }

  // FileType _getFileType(FileTypeEnum allowedTypes) {
  //   switch (allowedTypes) {
  //     case FileTypeEnum.image:
  //       return FileType.image;
  //     case FileTypeEnum.pdf:
  //       return FileType.custom;
  //     case FileTypeEnum.any:
  //     default:
  //       return FileType.any;
  //   }
  // }

  List<String>? _getAllowedExtensions(FileTypeEnum allowedTypes) {
    switch (allowedTypes) {
      case FileTypeEnum.pdf:
        return ['pdf'];
      case FileTypeEnum.image:
        return null; // Let FilePicker handle image extensions
      case FileTypeEnum.any:
      default:
        return null;
    }
  }

  Future<void> _submitDocuments() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create DocumentSubmission objects from uploaded files
      final List<DocumentSubmission> uploadedDocs = [];

      for (var entry in _uploadedFiles.entries) {
        final fieldIndex = entry.key;
        final files = entry.value;
        final fieldTitle = widget.documentFields[fieldIndex].title;

        for (var file in files) {
          uploadedDocs.add(DocumentSubmission(
            title: fieldTitle,
            file: file.path,
          ));
        }
      }

      // Add documents to user fields
      controler.user.value.fields.addAll(uploadedDocs);
      // controler.user.update((user) {});
      // Submit user data and documents
      await controler.submitUserDataAndDocs(controler.user.value);

      Get.snackbar(
        'Success',
        'Documents submitted successfully!',
        backgroundColor: AppColors.onlineGreen,
        colorText: AppColors.white,
      );

      // Navigate back or to next screen
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Submission Error',
        'Failed to submit documents: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

class DocumentField {
  final String title;
  final String description;
  final int maxFiles;
  final FileTypeEnum allowedTypes;

  const DocumentField({
    required this.title,
    this.description = '',
    this.maxFiles = 1,
    this.allowedTypes = FileTypeEnum.any,
  });
}

enum FileTypeEnum {
  image,
  pdf,
  any,
}
