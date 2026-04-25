class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.credits,
    required this.plan,
    required this.createdAt,
  });

  final String id;
  final String email;
  final int credits;
  final String plan;
  final DateTime createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      credits: (map['credits'] ?? 0) as int,
      plan: (map['plan'] ?? 'free') as String,
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.currentPeriodEnd,
    this.lastCreditRefillAt,
  });

  final String plan;
  final String status;
  final DateTime? currentPeriodEnd;
  final DateTime? lastCreditRefillAt;

  bool get isActive => status == 'active';

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      plan: (map['plan'] ?? 'free') as String,
      status: (map['status'] ?? 'inactive') as String,
      currentPeriodEnd: map['current_period_end'] == null
          ? null
          : DateTime.tryParse(map['current_period_end'] as String),
      lastCreditRefillAt: map['last_credit_refill_at'] == null
          ? null
          : DateTime.tryParse(map['last_credit_refill_at'] as String),
    );
  }
}

class TradeAnalysis {
  const TradeAnalysis({
    required this.marketSentiment,
    required this.entrySuggestion,
    required this.exitSuggestion,
    required this.riskLevel,
    required this.reasoning,
    required this.confidenceScore,
    required this.whatIsHappening,
    required this.whenToBuy,
    required this.whenToSell,
    required this.keySignals,
    required this.detectedIndicators,
  });

  final String marketSentiment;
  final String entrySuggestion;
  final String exitSuggestion;
  final String riskLevel;
  final String reasoning;
  final int confidenceScore;
  final String whatIsHappening;
  final String whenToBuy;
  final String whenToSell;
  final List<String> keySignals;
  final List<String> detectedIndicators;

  factory TradeAnalysis.fromMap(Map<String, dynamic> map) {
    List<String> toList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    return TradeAnalysis(
      marketSentiment: (map['marketSentiment'] ?? 'neutral') as String,
      entrySuggestion: (map['entrySuggestion'] ?? 'Wait for confirmation')
          as String,
      exitSuggestion: (map['exitSuggestion'] ?? 'Manage risk actively')
          as String,
      riskLevel: (map['riskLevel'] ?? 'medium') as String,
      reasoning: (map['reasoning'] ?? 'No reasoning returned.') as String,
      confidenceScore: (map['confidenceScore'] ?? 0) as int,
      whatIsHappening:
          (map['whatIsHappening'] ?? map['reasoning'] ?? '') as String,
      whenToBuy: (map['whenToBuy'] ?? map['entrySuggestion'] ?? '') as String,
      whenToSell: (map['whenToSell'] ?? map['exitSuggestion'] ?? '') as String,
      keySignals: toList(map['keySignals']),
      detectedIndicators: toList(map['detectedIndicators']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'marketSentiment': marketSentiment,
      'entrySuggestion': entrySuggestion,
      'exitSuggestion': exitSuggestion,
      'riskLevel': riskLevel,
      'reasoning': reasoning,
      'confidenceScore': confidenceScore,
      'whatIsHappening': whatIsHappening,
      'whenToBuy': whenToBuy,
      'whenToSell': whenToSell,
      'keySignals': keySignals,
      'detectedIndicators': detectedIndicators,
    };
  }
}

class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.imageUrl,
    required this.result,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final TradeAnalysis result;
  final DateTime createdAt;

  factory AnalysisRecord.fromMap(Map<String, dynamic> map) {
    return AnalysisRecord(
      id: map['id'] as String,
      imageUrl: (map['image_url'] ?? '') as String,
      result: TradeAnalysis.fromMap((map['result'] ?? {}) as Map<String, dynamic>),
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class DashboardState {
  const DashboardState({
    required this.profile,
    required this.analyses,
    this.subscription,
  });

  final UserProfile profile;
  final List<AnalysisRecord> analyses;
  final SubscriptionInfo? subscription;
}

class CheckoutProduct {
  const CheckoutProduct({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.description,
    required this.metadataValue,
    required this.mode,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String description;
  final String metadataValue;
  final String mode;
}

class AppCatalog {
  static const analysisCost = 10;

  static const subscriptions = <CheckoutProduct>[
    CheckoutProduct(
      id: 'starter',
      title: 'Starter',
      priceLabel: '\$1.99 / month',
      description: '125 credits every week',
      metadataValue: 'starter',
      mode: 'subscription',
    ),
    CheckoutProduct(
      id: 'pro',
      title: 'Pro',
      priceLabel: '\$5.99 / month',
      description: '250 credits every week',
      metadataValue: 'pro',
      mode: 'subscription',
    ),
    CheckoutProduct(
      id: 'trader',
      title: 'Trader',
      priceLabel: '\$12.99 / month',
      description: '525 credits every week',
      metadataValue: 'trader',
      mode: 'subscription',
    ),
    CheckoutProduct(
      id: 'money_printer',
      title: 'Money Printer',
      priceLabel: '\$19.99 / month',
      description: '925 credits every week',
      metadataValue: 'money_printer',
      mode: 'subscription',
    ),
  ];

  static const creditPacks = <CheckoutProduct>[
    CheckoutProduct(
      id: 'pack_50',
      title: '50 credits',
      priceLabel: '\$4.99',
      description: '5 extra chart analyses',
      metadataValue: 'pack_50',
      mode: 'payment',
    ),
    CheckoutProduct(
      id: 'pack_150',
      title: '150 credits',
      priceLabel: '\$11.99',
      description: '15 extra chart analyses',
      metadataValue: 'pack_150',
      mode: 'payment',
    ),
    CheckoutProduct(
      id: 'pack_500',
      title: '500 credits',
      priceLabel: '\$29.99',
      description: '50 extra chart analyses',
      metadataValue: 'pack_500',
      mode: 'payment',
    ),
  ];
}
