class SubmissionModel {
  final int id;
  final int userId;
  final int templateId;
  final String? originalImagePath;
  final String? processedImagePath;
  final String? originalImageUrl;
  final String? processedImageUrl;
  final String outputType;
  final String status;
  final String? errorMessage;
  final double? processingTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TemplateInfo? template;

  SubmissionModel({
    required this.id,
    required this.userId,
    required this.templateId,
    this.originalImagePath,
    this.processedImagePath,
    this.originalImageUrl,
    this.processedImageUrl,
    required this.outputType,
    required this.status,
    this.errorMessage,
    this.processingTime,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.template,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    // Construct full URLs for images if paths are provided
    String? originalImageUrl;
    String? processedImageUrl;
    
    if (json['original_image_path'] != null) {
      final path = json['original_image_path'] as String;
      originalImageUrl = 'https://trends.rektech.work/storage/$path';
    }
    
    if (json['processed_image_path'] != null) {
      final path = json['processed_image_path'] as String;
      processedImageUrl = 'https://trends.rektech.work/storage/$path';
    }
    
    return SubmissionModel(
      id: json['id'],
      userId: json['user_id'],
      templateId: json['template_id'],
      originalImagePath: json['original_image_path'],
      processedImagePath: json['processed_image_path'],
      originalImageUrl: originalImageUrl,
      processedImageUrl: processedImageUrl,
      outputType: json['output_type'],
      status: json['status'],
      errorMessage: json['error_message'],
      processingTime: json['processing_time']?.toDouble(),
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      template: json['template'] != null 
          ? TemplateInfo.fromJson(json['template']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'original_image_path': originalImagePath,
      'processed_image_path': processedImagePath,
      'original_image_url': originalImageUrl,
      'processed_image_url': processedImageUrl,
      'output_type': outputType,
      'status': status,
      'error_message': errorMessage,
      'processing_time': processingTime,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'template': template?.toJson(),
    };
  }
}

class TemplateInfo {
  final String title;

  TemplateInfo({required this.title});

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(title: json['title']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title};
  }
}
