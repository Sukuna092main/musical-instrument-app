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
    const activeStatuses = ['active', 'trial'];
    return activeStatuses.contains(status) && expiredAt.isAfter(DateTime.now());
  }

  bool get isTrial => status == 'trial';

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

class ManualPaymentRequest {
  const ManualPaymentRequest({
    required this.id,
    required this.planCode,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    required this.transferCode,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String planCode;
  final int amount;
  final String currency;
  final String provider;
  final String status; // pending | approved | rejected
  final String? transferCode;
  final String? note;
  final DateTime createdAt;

  factory ManualPaymentRequest.fromJson(Map<String, dynamic> json) {
    final plan = json['vip_plans'] as Map<String, dynamic>?;
    return ManualPaymentRequest(
      id: json['id'] as String,
      planCode: plan?['code'] as String? ?? '',
      amount: (json['amount'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'VND',
      provider: (json['provider'] as String?) ?? 'bank_transfer',
      status: (json['status'] as String?) ?? 'pending',
      transferCode: json['transfer_code'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ManualPaymentInfo {
  const ManualPaymentInfo({
    required this.configured,
    this.bankId,
    this.accountNo,
    this.accountName,
    this.amount,
    this.currency,
    this.transferRef,
    this.qrUrl,
  });

  final bool configured;
  final String? bankId;
  final String? accountNo;
  final String? accountName;
  final int? amount;
  final String? currency;
  final String? transferRef;
  final String? qrUrl;

  factory ManualPaymentInfo.fromJson(Map<String, dynamic> json) {
    final configured = json['configured'] == true;
    return ManualPaymentInfo(
      configured: configured,
      bankId: json['bankId'] as String?,
      accountNo: json['accountNo'] as String?,
      accountName: json['accountName'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toInt() : null,
      currency: json['currency'] as String?,
      transferRef: json['transferRef'] as String?,
      qrUrl: json['qrUrl'] as String?,
    );
  }
}

class ManualRequestResult {
  const ManualRequestResult({
    required this.request,
    required this.paymentInfo,
    this.trialHours = 0,
  });

  final ManualPaymentRequest? request;
  final ManualPaymentInfo paymentInfo;
  final int trialHours;

  factory ManualRequestResult.fromJson(Map<String, dynamic> json) {
    final rawRequest = json['request'] as Map<String, dynamic>?;
    final rawInfo = json['paymentInfo'] as Map<String, dynamic>? ?? {};
    return ManualRequestResult(
      request: rawRequest != null
          ? ManualPaymentRequest.fromJson(Map<String, dynamic>.from(rawRequest))
          : null,
      paymentInfo: ManualPaymentInfo.fromJson(
        Map<String, dynamic>.from(rawInfo),
      ),
      trialHours: (json['trialHours'] as num?)?.toInt() ?? 0,
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

  // POST /api/payments/manual/request
  // Tạo yêu cầu mua VIP qua chuyển khoản. Backend cấp trial 24h ngay lập tức.
  Future<ManualRequestResult> requestManualVip(
    String planCode, {
    String? transferCode,
    String? note,
  }) async {
    final body = <String, dynamic>{'planCode': planCode};
    if (transferCode != null && transferCode.isNotEmpty) {
      body['transferCode'] = transferCode;
    }
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    final response = await _client.post('/api/payments/manual/request', body);
    return ManualRequestResult.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  // GET /api/payments/manual/my-requests
  // Xem danh sách yêu cầu chuyển khoản của user.
  Future<List<ManualPaymentRequest>> getMyManualRequests() async {
    final response = await _client.get('/api/payments/manual/my-requests');
    if (response is! Map) return [];
    final items = response['items'];
    if (items is! List) return [];
    return items
        .map(
          (item) => ManualPaymentRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
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
