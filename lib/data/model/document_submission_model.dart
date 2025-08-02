import 'package:json_annotation/json_annotation.dart';

part 'document_submission_model.g.dart';

@JsonSerializable()
class DocumentSubmission {
  final String title;
  final String file; // Can be an image or document path/URL.

  DocumentSubmission({
    required this.title,
    required this.file,
  });

  factory DocumentSubmission.fromJson(Map<String, dynamic> json) =>
      _$DocumentSubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentSubmissionToJson(this);
}
