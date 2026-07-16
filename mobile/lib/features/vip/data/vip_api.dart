import '../../../core/network/api_client.dart';

class VipPlan {
  const VipPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final int price;
  final String currency;
  final int durationDays;
  final List<String> features;

  factory VipPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : <String>[];

    return VipPlan(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'VND',
      durationDays: (json['duration_days'] as num).toInt(),
      features: features,
    );
  }
}

class VipSubscription {
  const VipSubscription({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.expiredAt,
    required this.planName,
    required this.planCode,
  });

  final String id;
  final String status;
  final DateTime startedAt;
  final DateTime expiredAt;
  final String planName;
  final String planCode;

  bool get isActive {
    return status == 'active' && expiredAt.isAfter(DateTime.now());
  }

  int get daysRemaining {
    final diff = expiredAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory VipSubscription.fromJson(Map<String, dynamic> json) {
    final plan = json['vip_plans'] as Map<String, dynamic>?;

    return VipSubscription(
      id: json['id'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiredAt: DateTime.parse(json['expired_at'] as String),
      planName: plan?['name'] as String? ?? 'VIP',
      planCode: plan?['code'] as String? ?? '',
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.planName,
  });

  final String id;
  final int amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String planName;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final plan = json['vip_plans'] as Map<String, dynamic>?;

    return PaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'VND',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      planName: plan?['name'] as String? ?? 'VIP',
    );
  }
}

class VipApi {
  VipApi(this._client);

  final ApiClient _client;

  Future<List<VipPlan>> getPlans() async {
    final response = await _client.get('/api/vip/plans');

    if (response is! List) return [];

    return response
        .map((item) => VipPlan.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<VipSubscription?> getMySubscription() async {
    final response = await _client.get('/api/vip/subscription');

    if (response == null) return null;

    return VipSubscription.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> devPurchase(String planCode) async {
    await _client.post('/api/payments/dev-success', {'planCode': planCode});
  }

  Future<List<PaymentRecord>> getPaymentHistory() async {
    final response = await _client.get('/api/payments/history');

    if (response is! List) return [];

    return response
        .map(
          (item) =>
              PaymentRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
