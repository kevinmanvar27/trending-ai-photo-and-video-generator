/// Model for AI Generation based on new API documentation
/// IMPORTANT: Use submission_id (not generation_id) for status polling
class GenerationModel {
  final String generationId; // String ID for reference (e.g., "gen_abc123")
  final int submissionId; // Integer ID used for status polling (CRITICAL)
  final int? templateId;
  final String? templateName;
  final String status; // processing, completed, failed
  final int? progress; // 0-100
  final String? message;
  final int? estimatedTimeRemaining; // seconds
  final String? originalImage;
  final String? generatedOutput;
  final String? thumbnail;
  final String? type; // image, video
  final TemplateUsed? templateUsed;
  final String? appliedPrompt;
  final int? estimatedTime;
  final int? coinsDeducted; // Coins deducted for this generation
  final int? remainingCoins; // User's remaining coins after generation
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;

  GenerationModel({
    required this.generationId,
    required this.submissionId,
    this.templateId,
    this.templateName,
    required this.status,
    this.progress,
    this.message,
    this.estimatedTimeRemaining,
    this.originalImage,
    this.generatedOutput,
    this.thumbnail,
    this.type,
    this.templateUsed,
    this.appliedPrompt,
    this.estimatedTime,
    this.coinsDeducted,
    this.remainingCoins,
    this.error,
    this.createdAt,
    this.completedAt,
    this.failedAt,
  });

  factory GenerationModel.fromJson(Map<String, dynamic> json) {
    // Handle both nested 'data' and direct response
    final data = json['data'] ?? json;
    
    return GenerationModel(
      generationId: data['generation_id']?.toString() ?? '',
      submissionId: data['submission_id'] ?? 0, // CRITICAL: Used for status polling
      templateId: data['template_id'],
      templateName: data['template_name'],
      status: data['status'] ?? 'unknown',
      progress: data['progress'],
      message: data['message'],
      estimatedTimeRemaining: data['estimated_time_remaining'],
      originalImage: data['original_image'] ?? data['uploaded_image'],
      generatedOutput: data['generated_output'],
      thumbnail: data['thumbnail'],
      type: data['type'],
      templateUsed: data['template_used'] != null 
          ? TemplateUsed.fromJson(data['template_used']) 
          : null,
      appliedPrompt: data['applied_prompt'],
      estimatedTime: data['estimated_time'],
      coinsDeducted: data['coins_deducted'],
      remainingCoins: data['remaining_coins'],
      error: data['error'],
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : null,
      completedAt: data['completed_at'] != null 
          ? DateTime.parse(data['completed_at']) 
          : null,
      failedAt: data['failed_at'] != null 
          ? DateTime.parse(data['failed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generation_id': generationId,
      'submission_id': submissionId,
      'template_id': templateId,
      'template_name': templateName,
      'status': status,
      'progress': progress,
      'message': message,
      'estimated_time_remaining': estimatedTimeRemaining,
      'original_image': originalImage,
      'generated_output': generatedOutput,
      'thumbnail': thumbnail,
      'type': type,
      'template_used': templateUsed?.toJson(),
      'applied_prompt': appliedPrompt,
      'estimated_time': estimatedTime,
      'coins_deducted': coinsDeducted,
      'remaining_coins': remainingCoins,
      'error': error,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
    };
  }

  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
}

class TemplateUsed {
  final int id;
  final String name;

  TemplateUsed({
    required this.id,
    required this.name,
  });

  factory TemplateUsed.fromJson(Map<String, dynamic> json) {
    return TemplateUsed(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// Model for Generation History Response
class GenerationHistoryResponse {
  final List<GenerationModel> generations;
  final PaginationInfo pagination;

  GenerationHistoryResponse({
    required this.generations,
    required this.pagination,
  });

  factory GenerationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return GenerationHistoryResponse(
      generations: (data['generations'] as List?)
          ?.map((item) => GenerationModel.fromJson(item))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(data['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      itemsPerPage: json['items_per_page'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'total_items': totalItems,
      'items_per_page': itemsPerPage,
    };
  }
}
