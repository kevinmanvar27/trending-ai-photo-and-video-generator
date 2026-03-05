class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? referralCode;
  final int? referralCoins;
  final UserSubscription? activeSubscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.referralCode,
    this.referralCoins,
    this.activeSubscription,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle referral data from nested object (profile API) or direct fields (login API)
    String? referralCode;
    int? referralCoins;
    
    if (json['referral'] != null) {
      // Profile API format: nested referral object
      referralCode = json['referral']['referral_code'];
      referralCoins = json['referral']['referral_coins'];
    } else {
      // Login API format: direct fields
      referralCode = json['referral_code'];
      referralCoins = json['referral_coins'];
    }
    
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'user',
      referralCode: referralCode,
      referralCoins: referralCoins,
      activeSubscription: json['active_subscription'] != null
          ? UserSubscription.fromJson(json['active_subscription'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'referral_code': referralCode,
      'referral_coins': referralCoins,
      'active_subscription': activeSubscription?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class UserSubscription {
  final PlanInfo plan;

  UserSubscription({required this.plan});

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      plan: PlanInfo.fromJson(json['plan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan.toJson(),
    };
  }
}

class PlanInfo {
  final String name;

  PlanInfo({required this.name});

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
