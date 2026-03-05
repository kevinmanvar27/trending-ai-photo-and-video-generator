class TemplateModel {
  final int id;
  final String name; // Changed from 'title' to match new API
  final String? description;
  final String category;
  final String? thumbnail;
  final String prompt;
  final String? negativePrompt;
  final String type;
  final Map<String, dynamic>? settings;
  final List<String>? sampleOutputs;
  final bool isActive;
  final int usageCount;
  final int coinsRequired; // For backward compatibility
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Legacy field for backward compatibility
  String get title => name;
  String? get referenceImageUrl => thumbnail;

  TemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.thumbnail,
    required this.prompt,
    this.negativePrompt,
    required this.type,
    this.settings,
    this.sampleOutputs,
    required this.isActive,
    required this.usageCount,
    required this.coinsRequired,
    required this.createdAt,
    this.updatedAt,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    // Handle both new API format and legacy format
    String? thumbnailUrl;
    
    // New API: 'thumbnail' field with full URL
    if (json['thumbnail'] != null) {
      thumbnailUrl = json['thumbnail'] as String;
    } 
    // Legacy: 'reference_image_path' needs base URL
    else if (json['reference_image_path'] != null) {
      final imagePath = json['reference_image_path'] as String;
      thumbnailUrl = 'https://trends.rektech.work/storage/$imagePath';
    } 
    // Legacy: 'reference_image_url' direct URL
    else if (json['reference_image_url'] != null) {
      thumbnailUrl = json['reference_image_url'] as String;
    }
    
    // Parse settings if it's a JSON string
    Map<String, dynamic>? settings;
    if (json['settings'] != null) {
      if (json['settings'] is String) {
        // If settings is a JSON string, parse it
        try {
          settings = Map<String, dynamic>.from(json['settings']);
        } catch (e) {
          print('⚠️ Failed to parse settings: $e');
        }
      } else if (json['settings'] is Map) {
        settings = Map<String, dynamic>.from(json['settings']);
      }
    }
    
    // Parse sample outputs
    List<String>? sampleOutputs;
    if (json['sample_outputs'] != null && json['sample_outputs'] is List) {
      sampleOutputs = (json['sample_outputs'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return TemplateModel(
      id: json['id'],
      name: json['name'] ?? json['title'] ?? '', // Support both 'name' and 'title'
      description: json['description'],
      category: json['category'] ?? 'general',
      thumbnail: thumbnailUrl,
      prompt: json['prompt'] ?? '',
      negativePrompt: json['negative_prompt'],
      type: json['type'] ?? 'image',
      settings: settings,
      sampleOutputs: sampleOutputs,
      isActive: json['is_active'] ?? true,
      usageCount: json['usage_count'] ?? 0,
      coinsRequired: json['coins_required'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'thumbnail': thumbnail,
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'type': type,
      'settings': settings,
      'sample_outputs': sampleOutputs,
      'is_active': isActive,
      'usage_count': usageCount,
      'coins_required': coinsRequired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
