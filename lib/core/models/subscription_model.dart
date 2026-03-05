class SubscriptionPlanModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String durationType;
  final int durationValue;
  final int coins;
  final List<String>? features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationType,
    required this.durationValue,
    required this.coins,
    this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown Plan',
      description: json['description'],
      price: _parsePrice(json['price']), // Handle both String and num
      durationType: json['duration_type'] ?? 'month', // Default to 'month' if null
      durationValue: json['duration_value'] ?? 1, // Default to 1 if null
      coins: json['coins'] ?? 0,
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
  
  // Helper method to parse price (handles both String and num)
  static double _parsePrice(dynamic price) {
    if (price is num) {
      return price.toDouble();
    } else if (price is String) {
      return double.parse(price);
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_type': durationType,
      'duration_value': durationValue,
      'coins': coins,
      'features': features,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get durationText {
    // Convert duration_type to readable format
    String unit = durationType;
    
    // Handle different formats: "monthly" -> "month", "yearly" -> "year"
    // Or already in correct format: "month", "year"
    if (unit.endsWith('ly')) {
      unit = unit.substring(0, unit.length - 2); // Remove "ly"
    }
    
    if (durationValue == 1) {
      return '1 $unit';
    }
    return '$durationValue ${unit}s';
  }
}

class UserSubscriptionModel {
  final int id;
  final int userId;
  final int subscriptionPlanId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String status;
  final int coinsUsed;
  final int? remainingCoinsFromApi; // Store remaining_coins from API
  final int? daysRemaining; // New field from API
  final DateTime? cancelledAt;
  final DateTime? createdAt; // Made optional
  final DateTime? updatedAt; // Made optional
  final SubscriptionPlanModel? plan;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.subscriptionPlanId,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    required this.coinsUsed,
    this.remainingCoinsFromApi,
    this.daysRemaining,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: json['id'],
      userId: json['user_id'],
      subscriptionPlanId: json['subscription_plan_id'],
      startedAt: DateTime.parse(json['started_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'],
      coinsUsed: json['coins_used'] ?? 0,
      remainingCoinsFromApi: json['remaining_coins'], // Get from API if available
      daysRemaining: json['days_remaining'], // New field
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      plan: json['plan'] != null 
          ? SubscriptionPlanModel.fromJson(json['plan']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscription_plan_id': subscriptionPlanId,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'coins_used': coinsUsed,
      'remaining_coins': remainingCoinsFromApi,
      'days_remaining': daysRemaining,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'plan': plan?.toJson(),
    };
  }

  int get remainingCoins {
    // Prefer API value if available, otherwise calculate
    if (remainingCoinsFromApi != null) {
      return remainingCoinsFromApi!;
    }
    if (plan == null) return 0;
    return plan!.coins - coinsUsed;
  }

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
}
