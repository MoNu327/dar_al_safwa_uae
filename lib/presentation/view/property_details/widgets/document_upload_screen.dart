// import 'package:majan/data/model/user_data_submission_model.dart';
// import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
// import 'package:majan/presentation/widgets/custom_text_widget.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'dart:io';

// import '../../../../core/constants/custom_size.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../controller/user_data_submission_controller.dart';

// class DocumentUploadScreen extends StatefulWidget {
//   final String screenTitle;
//   final List<DocumentField> documentFields;
//   final bool isCommercialProperty;

//   const DocumentUploadScreen({
//     super.key,
//     required this.screenTitle,
//     required this.documentFields,
//     this.isCommercialProperty = false,
//   });

//   @override
//   State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
// }

// class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
//   final Map<int, List<File>> _uploadedFiles = {};
//   final Map<int, List<File>> _additionalFiles = {};
//   final Map<int, List<String>> _additionalTitles = {};
//   bool _isSubmitting = false;
//   final controller = Get.find<UserDataSubmissionController>();
//   final user = Get.put(AuthService());

//   // Document type mapping based on field titles
//   final Map<String, String> _documentTypeMapping = {
//     'Civil ID Front': 'civil_id_front',
//     'Civil ID Back': 'civil_id_back',
//     'Passport First Page': 'passport_first_page',
//     'Passport Last Page': 'passport_last_page',
//     'Passport Visa Page': 'passport_visa_page',
//     'Resident Visa': 'resident_visa',
//     'Expat Civil ID Front': 'expat_civil_id_front',
//     'Expat Civil ID Back': 'expat_civil_id_back',
//     'Commercial Registration': 'cr_document',
//     'Municipality License': 'municipality_license',
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//           onPressed: () {
//             Get.back();
//           },
//           icon: Icon(Icons.arrow_back),
//           color: AppColors.white,
//         ),
//         backgroundColor: AppColors.secondaryColor,
//         title: CustomTextWidget(
//           color: AppColors.white,
//           title: widget.screenTitle,
//           fontSize: appBarTitles,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth5,
//           vertical: screenHeight2,
//         ),
//         child: Obx(() => Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             // User Information Display
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               margin: EdgeInsets.only(bottom: 20),
//               decoration: BoxDecoration(
//                 color: AppColors.secondaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CustomTextWidget(
//                     title: "Submitting for: ${controller.user.value.firstName} ${controller.user.value.lastName}",
//                     fontSize: packageTitle,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.secondaryColor,
//                   ),
//                   kHeight(0.01),
//                   Text(
//                     "Citizenship: ${controller.user.value.isNative ? 'Native' : 'Foreign'}",
//                     style: TextStyle(
//                       fontSize: detailContentTitle,
//                       color: AppColors.black600,
//                     ),
//                   ),
//                   if (widget.isCommercialProperty) ...[
//                     Text(
//                       "Property Type: Commercial",
//                       style: TextStyle(
//                         fontSize: detailContentTitle,
//                         color: AppColors.black600,
//                       ),
//                     ),
//                   ],
//                   Text(
//                     "Email: ${controller.user.value.email}",
//                     style: TextStyle(
//                       fontSize: detailContentTitle,
//                       color: AppColors.black600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             CustomTextWidget(
//               title: "Upload Required Documents *",
//               fontSize: tagTitle,
//               fontWeight: FontWeight.bold,
//               fontStyle: FontStyle.italic,
//               overflow: TextOverflow.ellipsis,
//             ),
//             kHeight(0.02),

//             // Required Documents Section
//             ...widget.documentFields.asMap().entries.map((entry) {
//               final index = entry.key;
//               final field = entry.value;
//               return _buildDocumentField(index, field, isRequired: true);
//             }),

//             kHeight(0.03),

//             // Additional Documents Section
//             CustomTextWidget(
//               title: "Additional Documents (Optional)",
//               fontSize: tagTitle,
//               fontWeight: FontWeight.w600,
//               color: AppColors.black600,
//               overflow: TextOverflow.ellipsis,
//             ),
//             kHeight(0.01),
//             Text(
//               "You can upload any additional supporting documents here",
//               style: TextStyle(
//                 fontSize: detailContentTitle,
//                 color: AppColors.black500,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//             kHeight(0.02),

//             _buildAdditionalDocumentsSection(),

//             kHeight(0.05),

//             // Error Display
//             if (controller.errorMessage.value != null)
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 margin: EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.shade300),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.error, color: Colors.red),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         controller.errorMessage.value!,
//                         style: TextStyle(color: Colors.red.shade700),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             _buildSubmitButton(),
//           ],
//         )),
//       ),
//     );
//   }

//   Widget _buildDocumentField(int index, DocumentField field, {bool isRequired = true}) {
//     final uploadedFiles = _uploadedFiles[index] ?? [];
//     final canUploadMore = uploadedFiles.length < field.maxFiles;

//     return Container(
//       margin: EdgeInsets.only(bottom: screenHeight3),
//       padding: EdgeInsets.all(screenWidth3),
//       decoration: BoxDecoration(
//         color: AppColors.whiteLight,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(
//           color: isRequired ? AppColors.secondaryColor.withOpacity(0.5) : AppColors.lightGrey,
//           width: isRequired ? 1.5 : 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               if (isRequired)
//                 Icon(
//                   Icons.star,
//                   color: Colors.red,
//                   size: 12,
//                 ),
//               if (isRequired) SizedBox(width: 4),
//               Expanded(
//                 child: Text(
//                   field.title,
//                   style: TextStyle(
//                     fontSize: packageTitle,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.black,
//                   ),
//                 ),
//               ),
//               if (uploadedFiles.isNotEmpty)
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: AppColors.onlineGreen,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.check, color: AppColors.white, size: 12),
//                       SizedBox(width: 4),
//                       Text(
//                         'Uploaded',
//                         style: TextStyle(
//                           color: AppColors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//           if (field.description.isNotEmpty) ...[
//             kHeight(0.01),
//             Text(
//               field.description,
//               style: TextStyle(
//                 fontSize: detailContentTitle,
//                 color: AppColors.black600,
//               ),
//             ),
//           ],
//           kHeight(0.02),
//           if (uploadedFiles.isNotEmpty) ...[
//             ...uploadedFiles.map((file) => _buildUploadedFileItem(file, index, isRequired)),
//             kHeight(0.02),
//           ],
//           if (canUploadMore)
//             _buildUploadButton(
//               index: index,
//               field: field,
//               isFirstUpload: uploadedFiles.isEmpty,
//               isRequired: isRequired,
//             ),
//           if (field.maxFiles > 1 && uploadedFiles.isNotEmpty && canUploadMore)
//             Text(
//               'You can upload ${field.maxFiles - uploadedFiles.length} more ${field.maxFiles - uploadedFiles.length == 1 ? 'file' : 'files'}',
//               style: TextStyle(
//                 fontSize: expandedContentTitle,
//                 color: AppColors.black500,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAdditionalDocumentsSection() {
//     return Container(
//       padding: EdgeInsets.all(screenWidth3),
//       decoration: BoxDecoration(
//         color: AppColors.lightGrey.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.lightGrey),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Additional Documents',
//             style: TextStyle(
//               fontSize: detailContentTitle,
//               fontWeight: FontWeight.w600,
//               color: AppColors.black,
//             ),
//           ),
//           kHeight(0.02),
          
//           if (_additionalFiles.isNotEmpty) ...[
//             ..._additionalFiles.entries.map((entry) {
//               final index = entry.key;
//               final files = entry.value;
//               final titles = _additionalTitles[index] ?? [];
                           
//               return Column(
//                 children: files.asMap().entries.map((fileEntry) {
//                   final fileIndex = fileEntry.key;
//                   final file = fileEntry.value;
//                   final title = fileIndex < titles.length ? titles[fileIndex] : 'Additional Document';
                                   
//                   return Container(
//                     margin: EdgeInsets.only(bottom: 8),
//                     child: _buildUploadedFileItem(file, index, false, title: title),
//                   );
//                 }).toList(),
//               );
//             }).toList(),
//             kHeight(0.02),
//           ],
                   
//           InkWell(
//             onTap: () => _handleAdditionalFileUpload(),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth3, 
//                 vertical: screenHeight2
//               ),
//               decoration: BoxDecoration(
//                 color: AppColors.white,
//                 border: Border.all(
//                   color: AppColors.black.withOpacity(0.2),
//                   style: BorderStyle.solid,
//                   width: 1,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.upload_file_outlined,
//                     size: iconSize,
//                     color: AppColors.black.withOpacity(0.6),
//                   ),
//                   kWidth(0.02),
//                   Text(
//                     'Upload Additional Document',
//                     style: TextStyle(
//                       fontSize: detailContentTitle,
//                       color: AppColors.black.withOpacity(0.6),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           kHeight(0.01),
//           Text(
//             'Supported formats: PDF, DOC, DOCX, JPG, PNG',
//             style: TextStyle(
//               fontSize: detailContentTitle * 0.8,
//               color: AppColors.black.withOpacity(0.4),
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUploadedFileItem(File file, int fieldIndex, bool isRequired, {String? title}) {
//     return Container(
//       margin: EdgeInsets.only(bottom: screenHeight1),
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth2,
//         vertical: screenHeight1,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: AppColors.lightGrey),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _getFileIcon(file.path),
//             size: iconSize,
//             color: AppColors.secondaryColor,
//           ),
//           kWidth(0.02),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (title != null)
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: detailContentTitle,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.black,
//                     ),
//                   ),
//                 Text(
//                   file.path.split('/').last,
//                   style: TextStyle(
//                     fontSize: expandedContentTitle,
//                     color: AppColors.black600,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.close, size: smallIconSize),
//             onPressed: () {
//               setState(() {
//                 if (isRequired) {
//                   _uploadedFiles[fieldIndex]?.remove(file);
//                   if (_uploadedFiles[fieldIndex]?.isEmpty ?? false) {
//                     _uploadedFiles.remove(fieldIndex);
//                   }
//                 } else {
//                   _additionalFiles[fieldIndex]?.remove(file);
//                   if (_additionalFiles[fieldIndex]?.isEmpty ?? false) {
//                     _additionalFiles.remove(fieldIndex);
//                     _additionalTitles.remove(fieldIndex);
//                   }
//                 }
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUploadButton({
//     required int index,
//     required DocumentField field,
//     required bool isFirstUpload,
//     required bool isRequired,
//   }) {
//     return OutlinedButton(
//       style: OutlinedButton.styleFrom(
//         backgroundColor: isFirstUpload
//             ? AppColors.secondaryColor.withOpacity(0.1)
//             : AppColors.white,
//         side: BorderSide(
//           color: isFirstUpload
//               ? AppColors.secondaryColor
//               : AppColors.black.withOpacity(0.2),
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth3,
//           vertical: screenHeight1,
//         ),
//       ),
//       onPressed: () => _handleFileUpload(index, field),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.cloud_upload,
//             size: iconSize,
//             color: isFirstUpload
//                 ? AppColors.secondaryColor
//                 : AppColors.black.withOpacity(0.6),
//           ),
//           kWidth(0.02),
//           Text(
//             isFirstUpload ? 'Upload ${field.title}' : 'Add Another',
//             style: TextStyle(
//               overflow: TextOverflow.ellipsis,
//               fontSize: detailContentTitle,
//               color: isFirstUpload
//                   ? AppColors.secondaryColor
//                   : AppColors.black.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     final allRequiredFieldsFilled = widget.documentFields.every((field) {
//       final index = widget.documentFields.indexOf(field);
//       return _uploadedFiles.containsKey(index) &&
//           _uploadedFiles[index]!.isNotEmpty;
//     });

//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: allRequiredFieldsFilled && !_isSubmitting
//               ? AppColors.secondaryColor
//               : AppColors.secondaryColor.withOpacity(0.5),
//           padding: EdgeInsets.symmetric(vertical: screenHeight2),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         onPressed: allRequiredFieldsFilled && !_isSubmitting ? _submitDocuments : null,
//         child: _isSubmitting
//             ? SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(
//                   color: AppColors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : Text(
//                 'Submit Application',
//                 style: TextStyle(
//                   fontSize: packageTitle,
//                   color: AppColors.white,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//       ),
//     );
//   }

//  Future<void> _handleFileUpload(int index, DocumentField field) async {
//   try {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
//       allowMultiple: field.maxFiles > 1,
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final files = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      
//       if (files.isNotEmpty) {
//         setState(() {
//           if (_uploadedFiles.containsKey(index)) {
//             // Check if adding these files would exceed maxFiles limit
//             if ((_uploadedFiles[index]!.length + files.length) <= field.maxFiles) {
//               _uploadedFiles[index]!.addAll(files);
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('You can only upload ${field.maxFiles} files for this field'),
//                   backgroundColor: AppColors.redColor,
//                 ),
//               );
//             }
//           } else {
//             _uploadedFiles[index] = files;
//           }
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${files.length} file(s) uploaded successfully'),
//             backgroundColor: AppColors.onlineGreen,
//           ),
//         );
//       }
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to upload file: ${e.toString()}'),
//         backgroundColor: AppColors.redColor,
//       ),
//     );
//   }
// }

// Future<void> _handleAdditionalFileUpload() async {
//   try {
//     // First get document title
//     String? title = await _showTitleDialog();
//     if (title == null || title.isEmpty) return;

//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
//       allowMultiple: false,
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final file = File(result.files.first.path!);
//       final nextIndex = _additionalFiles.keys.isEmpty ? 0 : _additionalFiles.keys.last + 1;

//       setState(() {
//         _additionalFiles[nextIndex] = [file];
//         _additionalTitles[nextIndex] = [title];
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Additional document uploaded successfully'),
//           backgroundColor: AppColors.onlineGreen,
//         ),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to upload additional document: ${e.toString()}'),
//         backgroundColor: AppColors.redColor,
//       ),
//     );
//   }
// }

//   Future<String?> _showTitleDialog() async {
//     String title = '';
//     return await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Document Title'),
//         content: TextField(
//           onChanged: (value) => title = value,
//           decoration: InputDecoration(
//             hintText: 'Enter document title (e.g. Salary Certificate)',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, title),
//             child: Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitDocuments() async {
//     setState(() {
//       _isSubmitting = true;
//       controller.errorMessage.value = null;
//     });

//     try {
//       // Validate all required documents are uploaded
//       final allRequiredFieldsFilled = widget.documentFields.every((field) {
//         final index = widget.documentFields.indexOf(field);
//         return _uploadedFiles.containsKey(index) && _uploadedFiles[index]!.isNotEmpty;
//       });

//       if (!allRequiredFieldsFilled) {
//         controller.errorMessage.value = 'Please upload all required documents before submitting';
//         return;
//       }

//       // Prepare required documents with proper document types
//       List<String> requiredDocuments = [];
//       List<String> requiredDocumentTypes = [];

//       for (var entry in _uploadedFiles.entries) {
//         final fieldIndex = entry.key;
//         final files = entry.value;
//         final fieldTitle = widget.documentFields[fieldIndex].title;
//         final documentType = _documentTypeMapping[fieldTitle] ?? 'unknown';

//         for (var file in files) {
//           requiredDocuments.add(file.path);
//           requiredDocumentTypes.add(documentType);
//         }
//       }

//       // Prepare additional documents
//       List<String> additionalDocuments = [];
//       List<String> additionalDocumentTitles = [];

//       for (var entry in _additionalFiles.entries) {
//         final index = entry.key;
//         final files = entry.value;
//         final titles = _additionalTitles[index] ?? [];

//         for (int i = 0; i < files.length; i++) {
//           additionalDocuments.add(files[i].path);
//           additionalDocumentTitles.add(i < titles.length ? titles[i] : 'Additional Document');
//         }
//       }

//       // Update user model with document information
//       controller.user.value = UserDataSubmissionModel(
//         uid: controller.user.value.uid,
//         firstName: controller.user.value.firstName,
//         lastName: controller.user.value.lastName,
//         address: controller.user.value.address,
//         citizenship: controller.user.value.citizenship,
//         email: controller.user.value.email,
//         mobile: controller.user.value.mobile,
//         propertyId: controller.user.value.propertyId,
//         unitId: controller.user.value.unitId,
//         propertyType: widget.isCommercialProperty ? 'commercial' : 'residential',
//         requiredDocumentTypes: requiredDocumentTypes,
//         requiredDocuments: requiredDocuments,
//         additionalDocuments: additionalDocuments.isNotEmpty ? additionalDocuments : null,
//         additionalDocumentTitles: additionalDocumentTitles.isNotEmpty ? additionalDocumentTitles : null,
//         // Citizenship-specific fields
//         civilId: controller.user.value.civilId,
//         civilIdExpiry: controller.user.value.civilIdExpiry,
//         passportNo: controller.user.value.passportNo,
//         visaNo: controller.user.value.visaNo,
//         visaExpiryDate: controller.user.value.visaExpiryDate,
//         expatCivilId: controller.user.value.expatCivilId,
//         expatCivilIdExpiry: controller.user.value.expatCivilIdExpiry,
//         // Commercial fields if applicable
//         crNumber: widget.isCommercialProperty ? controller.user.value.crNumber : null,
//         crExpiryDate: widget.isCommercialProperty ? controller.user.value.crExpiryDate : null,
//         municipalityLicenseNumber: widget.isCommercialProperty ? controller.user.value.municipalityLicenseNumber : null,
//         municipalityLicenseDate: widget.isCommercialProperty ? controller.user.value.municipalityLicenseDate : null,
//         companyAddress: widget.isCommercialProperty ? controller.user.value.companyAddress : null,
//         poBox: widget.isCommercialProperty ? controller.user.value.poBox : null,
//       );

//       // Submit user data and documents
//       await controller.submitUserDataAndDocs(controller.user.value);

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Application submitted successfully!'),
//           backgroundColor: AppColors.onlineGreen,
//           duration: Duration(seconds: 3),
//         ),
//       );

//       // Navigate back to home or confirmation screen
//       // Get.offAllNamed('/home'); // Adjust route as needed
      
//     } catch (e) {
//       controller.errorMessage.value = 'Failed to submit application: ${e.toString()}';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Submission failed. Please try again.'),
//           backgroundColor: AppColors.redColor,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   FileType _getFileType(FileTypeEnum allowedTypes) {
//     switch (allowedTypes) {
//       case FileTypeEnum.image:
//         return FileType.image;
//       case FileTypeEnum.pdf:
//         return FileType.custom;
//       case FileTypeEnum.any:
//       default:
//         return FileType.any;
//     }
//   }

//   List<String>? _getAllowedExtensions(FileTypeEnum allowedTypes) {
//     switch (allowedTypes) {
//       case FileTypeEnum.pdf:
//         return ['pdf'];
//       case FileTypeEnum.image:
//         return ['jpg', 'jpeg', 'png', 'webp'];
//       case FileTypeEnum.any:
//       default:
//         return null; // No restrictions
//     }
//   }

//   IconData _getFileIcon(String filePath) {
//     final extension = filePath.split('.').last.toLowerCase();
//     switch (extension) {
//       case 'pdf':
//         return Icons.picture_as_pdf;
//       case 'jpg':
//       case 'jpeg':
//       case 'png':
//       case 'webp':
//         return Icons.image;
//       case 'doc':
//       case 'docx':
//         return Icons.description;
//       default:
//         return Icons.insert_drive_file;
//     }
//   }
// }

// class DocumentField {
//   final String title;
//   final String description;
//   final int maxFiles;
//   final FileTypeEnum allowedTypes;

//   const DocumentField({
//     required this.title,
//     this.description = '',
//     this.maxFiles = 1,
//     this.allowedTypes = FileTypeEnum.any,
//   });
// }

// enum FileTypeEnum {
//   image,
//   pdf,
//   any,
// }