import '../../../core/network/api_client.dart';

// ──────────────────────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────────────────────

class AdminDashboard {
  const AdminDashboard({
    required this.revenue,
    required this.users,
    required this.subscriptions,
    required this.payments,
    required this.instruments,
  });

  final AdminRevenue revenue;
  final AdminUsersSummary users;
  final AdminSubscriptionsSummary subscriptions;
  final AdminPaymentsSummary payments;
  final AdminInstrumentsSummary instruments;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      revenue: AdminRevenue.fromJson(
        Map<String, dynamic>.from(json['revenue'] as Map? ?? {}),
      ),
      users: AdminUsersSummary.fromJson(
        Map<String, dynamic>.from(json['users'] as Map? ?? {}),
      ),
      subscriptions: AdminSubscriptionsSummary.fromJson(
        Map<String, dynamic>.from(json['subscriptions'] as Map? ?? {}),
      ),
      payments: AdminPaymentsSummary.fromJson(
        Map<String, dynamic>.from(json['payments'] as Map? ?? {}),
      ),
      instruments: AdminInstrumentsSummary.fromJson(
        Map<String, dynamic>.from(json['instruments'] as Map? ?? {}),
      ),
    );
  }
}

class AdminRevenue {
  const AdminRevenue({
    required this.grossTotal,
    required this.refundedTotal,
    required this.netTotal,
    required this.today,
    required this.last7Days,
    required this.last30Days,
  });

  final int grossTotal;
  final int refundedTotal;
  final int netTotal;
  final int today;
  final int last7Days;
  final int last30Days;

  factory AdminRevenue.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminRevenue(
      grossTotal: n('grossTotal'),
      refundedTotal: n('refundedTotal'),
      netTotal: n('netTotal'),
      today: n('today'),
      last7Days: n('last7Days'),
      last30Days: n('last30Days'),
    );
  }
}

class AdminUsersSummary {
  const AdminUsersSummary({
    required this.total,
    required this.newToday,
    required this.newLast7Days,
    required this.blocked,
  });

  final int total;
  final int newToday;
  final int newLast7Days;
  final int blocked;

  factory AdminUsersSummary.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminUsersSummary(
      total: n('total'),
      newToday: n('newToday'),
      newLast7Days: n('newLast7Days'),
      blocked: n('blocked'),
    );
  }
}

class AdminSubscriptionsSummary {
  const AdminSubscriptionsSummary({
    required this.active,
    required this.newThisMonth,
    required this.expired,
    required this.cancelled,
  });

  final int active;
  final int newThisMonth;
  final int expired;
  final int cancelled;

  factory AdminSubscriptionsSummary.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminSubscriptionsSummary(
      active: n('active'),
      newThisMonth: n('newThisMonth'),
      expired: n('expired'),
      cancelled: n('cancelled'),
    );
  }
}

class AdminPaymentsSummary {
  const AdminPaymentsSummary({
    required this.success,
    required this.pending,
    required this.refunded,
    required this.failed,
  });

  final int success;
  final int pending;
  final int refunded;
  final int failed;

  factory AdminPaymentsSummary.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminPaymentsSummary(
      success: n('success'),
      pending: n('pending'),
      refunded: n('refunded'),
      failed: n('failed'),
    );
  }
}

class AdminInstrumentsSummary {
  const AdminInstrumentsSummary({
    required this.total,
    required this.free,
    required this.vip,
    required this.active,
    required this.hidden,
  });

  final int total;
  final int free;
  final int vip;
  final int active;
  final int hidden;

  factory AdminInstrumentsSummary.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminInstrumentsSummary(
      total: n('total'),
      free: n('free'),
      vip: n('vip'),
      active: n('active'),
      hidden: n('hidden'),
    );
  }
}

// ── Pagination wrapper ──

class Paginated<T> {
  const Paginated({required this.items, required this.pagination});

  final List<T> items;
  final AdminPagination pagination;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final Map<String, dynamic> actualJson = 
        (json.containsKey('data') && json['data'] is Map) 
            ? Map<String, dynamic>.from(json['data'] as Map) 
            : json;
            
    final itemsRaw = actualJson['items'] as List? ?? [];
    final items = <T>[];
    for (final item in itemsRaw) {
      items.add(fromJson(Map<String, dynamic>.from(item as Map)));
    }
    return Paginated(
      items: items,
      pagination: AdminPagination.fromJson(
        Map<String, dynamic>.from(actualJson['pagination'] as Map? ?? {}),
      ),
    );
  }
}

class AdminPagination {
  const AdminPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AdminPagination.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AdminPagination(
      page: n('page'),
      limit: n('limit'),
      total: n('total'),
      totalPages: n('totalPages'),
    );
  }
}

// ── User ──

class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String role;
  final String status;
  final DateTime createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      role: (json['role'] as String?) ?? 'user',
      status: (json['status'] as String?) ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Payment ──

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
    required this.planName,
    required this.planCode,
  });

  final String id;
  final String? userId;
  final int amount;
  final String currency;
  final String provider;
  final String status;
  final String? transactionId;
  final DateTime createdAt;
  final String userName;
  final String userEmail;
  final String planName;
  final String planCode;

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final plan = json['vip_plans'] as Map<String, dynamic>?;
    return AdminPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'VND',
      provider: (json['provider'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      transactionId: json['transaction_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userName: user?['full_name'] as String? ?? '',
      userEmail: user?['email'] as String? ?? '',
      planName: plan?['name'] as String? ?? '',
      planCode: plan?['code'] as String? ?? '',
    );
  }
}

// ── Subscription ──

class AdminSubscription {
  const AdminSubscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.startedAt,
    required this.expiredAt,
    required this.planName,
    required this.planCode,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final String? userId;
  final String status;
  final DateTime startedAt;
  final DateTime expiredAt;
  final String planName;
  final String planCode;
  final String userName;
  final String userEmail;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final plan = json['vip_plans'] as Map<String, dynamic>?;
    return AdminSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      status: (json['status'] as String?) ?? '',
      startedAt:
          DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiredAt:
          DateTime.tryParse(json['expired_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      planName: plan?['name'] as String? ?? '',
      planCode: plan?['code'] as String? ?? '',
      userName: user?['full_name'] as String? ?? '',
      userEmail: user?['email'] as String? ?? '',
    );
  }
}

// ── Instrument ──

class AdminInstrument {
  const AdminInstrument({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.audioSampleUrl,
    required this.isVip,
    required this.tags,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final String imageUrl;
  final String? audioSampleUrl;
  final bool isVip;
  final List<String> tags;
  final String status;
  final DateTime createdAt;

  factory AdminInstrument.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return AdminInstrument(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      audioSampleUrl: json['audio_sample_url'] as String?,
      isVip: json['is_vip'] == true,
      tags: rawTags is List ? rawTags.map((e) => e.toString()).toList() : [],
      status: (json['status'] as String?) ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    if (audioSampleUrl != null) 'audio_sample_url': audioSampleUrl,
    'is_vip': isVip,
    'tags': tags,
    'status': status,
  };
}

// ── VIP plan ──

class AdminVipPlan {
  const AdminVipPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final int price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final String status;

  factory AdminVipPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    return AdminVipPlan(
      id: json['id'] as String,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'VND',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      features: rawFeatures is List
          ? rawFeatures.map((e) => e.toString()).toList()
          : [],
      status: (json['status'] as String?) ?? 'active',
    );
  }

  Map<String, dynamic> toUpdatableJson() => {
    'name': name,
    if (description != null) 'description': description,
    'price': price,
    'currency': currency,
    'features': features,
    'status': status,
  };
}

// ── Manual payment request (bank transfer) ──

class AdminManualPayment {
  const AdminManualPayment({
    required this.id,
    required this.userId,
    required this.planId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.transferCode,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
    required this.planCode,
    required this.planName,
    required this.durationDays,
  });

  final String id;
  final String? userId;
  final String? planId;
  final int amount;
  final String currency;
  final String provider;
  final String? transferCode;
  final String? note;
  final String status; // pending | approved | rejected
  final DateTime createdAt;
  final String userName;
  final String userEmail;
  final String planCode;
  final String planName;
  final int durationDays;

  factory AdminManualPayment.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final plan = json['vip_plans'] as Map<String, dynamic>?;
    return AdminManualPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      planId: json['plan_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'VND',
      provider: (json['provider'] as String?) ?? 'bank_transfer',
      transferCode: json['transfer_code'] as String?,
      note: json['note'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userName: user?['full_name'] as String? ?? '',
      userEmail: user?['email'] as String? ?? '',
      planCode: plan?['code'] as String? ?? '',
      planName: plan?['name'] as String? ?? '',
      durationDays: (plan?['duration_days'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Lesson Category ──

class AdminLessonCategory {
  const AdminLessonCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.status,
    required this.lessonCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final String status;
  final int lessonCount;
  final DateTime createdAt;

  factory AdminLessonCategory.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map?;
    return AdminLessonCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      lessonCount: (count?['lessons'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Lesson ──

class AdminLesson {
  const AdminLesson({
    required this.id,
    required this.categoryId,
    this.instrumentId,
    required this.title,
    required this.slug,
    required this.content,
    required this.difficulty,
    required this.isVip,
    required this.sortOrder,
    required this.status,
    this.categoryName,
    this.instrumentName,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String? instrumentId;
  final String title;
  final String slug;
  final String content;
  final String difficulty;
  final bool isVip;
  final int sortOrder;
  final String status;
  final String? categoryName;
  final String? instrumentName;
  final DateTime createdAt;

  factory AdminLesson.fromJson(Map<String, dynamic> json) {
    final cat = json['lesson_categories'] as Map?;
    final inst = json['instruments'] as Map?;
    return AdminLesson(
      id: json['id'] as String,
      categoryId: (json['category_id'] as String?) ?? '',
      instrumentId: json['instrument_id'] as String?,
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      isVip: json['is_vip'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      categoryName: cat?['name'] as String?,
      instrumentName: inst?['name'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Chord ──

class AdminChord {
  const AdminChord({
    required this.id,
    this.instrumentId,
    required this.name,
    this.symbol,
    required this.category,
    this.diagramUrl,
    this.audioUrl,
    this.description,
    required this.difficulty,
    required this.isVip,
    required this.sortOrder,
    required this.status,
    this.instrumentName,
    required this.createdAt,
  });

  final String id;
  final String? instrumentId;
  final String name;
  final String? symbol;
  final String category;
  final String? diagramUrl;
  final String? audioUrl;
  final String? description;
  final String difficulty;
  final bool isVip;
  final int sortOrder;
  final String status;
  final String? instrumentName;
  final DateTime createdAt;

  factory AdminChord.fromJson(Map<String, dynamic> json) {
    final inst = json['instruments'] as Map?;
    return AdminChord(
      id: json['id'] as String,
      instrumentId: json['instrument_id'] as String?,
      name: (json['name'] as String?) ?? '',
      symbol: json['symbol'] as String?,
      category: (json['category'] as String?) ?? '',
      diagramUrl: json['diagram_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      description: json['description'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      isVip: json['is_vip'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      instrumentName: inst?['name'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Scale ──

class AdminScale {
  const AdminScale({
    required this.id,
    this.instrumentId,
    required this.name,
    this.key,
    required this.scaleType,
    this.diagramUrl,
    this.audioUrl,
    this.description,
    required this.difficulty,
    required this.isVip,
    required this.sortOrder,
    required this.status,
    this.instrumentName,
    required this.createdAt,
  });

  final String id;
  final String? instrumentId;
  final String name;
  final String? key;
  final String scaleType;
  final String? diagramUrl;
  final String? audioUrl;
  final String? description;
  final String difficulty;
  final bool isVip;
  final int sortOrder;
  final String status;
  final String? instrumentName;
  final DateTime createdAt;

  factory AdminScale.fromJson(Map<String, dynamic> json) {
    final inst = json['instruments'] as Map?;
    return AdminScale(
      id: json['id'] as String,
      instrumentId: json['instrument_id'] as String?,
      name: (json['name'] as String?) ?? '',
      key: json['key'] as String?,
      scaleType: (json['scale_type'] as String?) ?? '',
      diagramUrl: json['diagram_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      description: json['description'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      isVip: json['is_vip'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      instrumentName: inst?['name'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// API client
// ──────────────────────────────────────────────────────────────

/// Query parameters for list endpoints.
class AdminListQuery {
  const AdminListQuery({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.search,
    this.userId,
    this.role,
    this.provider,
    this.type,
    this.isVip,
    this.categoryId,
    this.instrumentId,
    this.difficulty,
    this.category,
    this.scaleType,
  });

  final int page;
  final int limit;
  final String? status;
  final String? search;
  final String? userId;
  final String? role;
  final String? provider;
  final String? type;
  final bool? isVip;
  final String? categoryId;
  final String? instrumentId;
  final String? difficulty;
  final String? category;
  final String? scaleType;

  Map<String, String> toQuery() {
    final q = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) q[key] = value;
    }

    add('status', status);
    add('search', search);
    add('userId', userId);
    add('role', role);
    add('provider', provider);
    add('type', type);
    add('categoryId', categoryId);
    add('instrumentId', instrumentId);
    add('difficulty', difficulty);
    add('category', category);
    add('scaleType', scaleType);
    if (isVip != null) q['isVip'] = isVip.toString();
    return q;
  }
}

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  String _withQuery(String path, AdminListQuery query) {
    final params = query.toQuery();
    if (params.isEmpty) return path;
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$path?$queryString';
  }

  // ── Dashboard ──

  /// GET /api/admin/dashboard
  Future<AdminDashboard> getDashboard() async {
    final response = await _client.get('/api/admin/dashboard');
    final map = Map<String, dynamic>.from(response as Map);
    return AdminDashboard.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }

  // ── Users ──

  /// GET /api/admin/users
  Future<Paginated<AdminUser>> listUsers({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(_withQuery('/api/admin/users', query));
    return Paginated<AdminUser>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminUser.fromJson(m),
    );
  }

  /// GET /api/admin/users/:id
  Future<AdminUser> getUser(String id) async {
    final response = await _client.get('/api/admin/users/$id');
    return AdminUser.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// PATCH /api/admin/users/:id/status — body: { status: 'active' | 'blocked' | 'deleted' }
  Future<void> updateUserStatus(String id, String status) async {
    await _client.patch('/api/admin/users/$id/status', {'status': status});
  }

  // ── Instruments ──

  /// GET /api/admin/instruments
  Future<Paginated<AdminInstrument>> listInstruments({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/instruments', query),
    );
    return Paginated<AdminInstrument>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminInstrument.fromJson(m),
    );
  }

  /// GET /api/admin/instruments/:id
  Future<AdminInstrument> getInstrument(String id) async {
    final response = await _client.get('/api/admin/instruments/$id');
    return AdminInstrument.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// POST /api/admin/instruments
  Future<void> createInstrument(AdminInstrument instrument) async {
    await _client.post('/api/admin/instruments', instrument.toJson());
  }

  /// PATCH /api/admin/instruments/:id
  Future<void> updateInstrument(String id, AdminInstrument instrument) async {
    await _client.patch('/api/admin/instruments/$id', instrument.toJson());
  }

  /// PATCH /api/admin/instruments/:id/status — body: { status }
  Future<void> updateInstrumentStatus(String id, String status) async {
    await _client.patch('/api/admin/instruments/$id/status', {
      'status': status,
    });
  }

  // ── VIP plans ──

  /// GET /api/admin/vip-plans
  Future<List<AdminVipPlan>> listVipPlans() async {
    final response = await _client.get('/api/admin/vip-plans');
    final map = Map<String, dynamic>.from(response as Map);
    final data = map['data'] ?? {};
    final items = data['items'] ?? [];
    if (items is! List) return [];
    return items
        .map((e) => AdminVipPlan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/admin/vip-plans/:id
  Future<AdminVipPlan> getVipPlan(String id) async {
    final response = await _client.get('/api/admin/vip-plans/$id');
    final map = Map<String, dynamic>.from(response as Map);
    return AdminVipPlan.fromJson(
      Map<String, dynamic>.from(map['vipPlan'] as Map? ?? response),
    );
  }

  /// PATCH /api/admin/vip-plans/:id — chỉ cho edit display/pricing fields.
  Future<void> updateVipPlan(String id, AdminVipPlan plan) async {
    await _client.patch('/api/admin/vip-plans/$id', plan.toUpdatableJson());
  }

  // ── Payments ──

  /// GET /api/admin/payments
  Future<Paginated<AdminPayment>> listPayments({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/payments', query),
    );
    final map = Map<String, dynamic>.from(response as Map);
    return Paginated<AdminPayment>.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? response),
      (m) => AdminPayment.fromJson(m),
    );
  }

  /// GET /api/admin/payments/:id
  Future<AdminPayment> getPayment(String id) async {
    final response = await _client.get('/api/admin/payments/$id');
    final map = Map<String, dynamic>.from(response as Map);
    return AdminPayment.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? response),
    );
  }

  // ── Subscriptions ──

  /// GET /api/admin/subscriptions
  Future<Paginated<AdminSubscription>> listSubscriptions({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/subscriptions', query),
    );
    final map = Map<String, dynamic>.from(response as Map);
    return Paginated<AdminSubscription>.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? response),
      (m) => AdminSubscription.fromJson(m),
    );
  }

  /// GET /api/admin/subscriptions/:id
  Future<AdminSubscription> getSubscription(String id) async {
    final response = await _client.get('/api/admin/subscriptions/$id');
    final map = Map<String, dynamic>.from(response as Map);
    return AdminSubscription.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? response),
    );
  }

  /// PATCH /api/admin/subscriptions/:id/status
  Future<void> updateSubscriptionStatus(String id, String status) async {
    await _client.patch('/api/admin/subscriptions/$id/status', {
      'status': status,
    });
  }

  // ── Manual payments (bank transfer) ──

  /// GET /api/admin/manual-payments?status=pending
  Future<Paginated<AdminManualPayment>> listManualPayments({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/manual-payments', query),
    );
    final map = Map<String, dynamic>.from(response as Map);
    return Paginated<AdminManualPayment>.fromJson(
      Map<String, dynamic>.from(map['data'] as Map? ?? response),
      (m) => AdminManualPayment.fromJson(m),
    );
  }

  /// POST /api/admin/manual-payments/:id/approve
  /// Sau khi duyệt: sub trial → active, expired = now + duration_days.
  Future<void> approveManualPayment(String id) async {
    await _client.post('/api/admin/manual-payments/$id/approve', {});
  }

  /// POST /api/admin/manual-payments/:id/reject — thu hồi trial ngay lập tức.
  Future<void> rejectManualPayment(String id, {String? reason}) async {
    await _client.post('/api/admin/manual-payments/$id/reject', {
      'reason': ?reason,
    });
  }

  // ── Lesson Categories ──

  /// GET /api/admin/lesson-categories
  Future<Paginated<AdminLessonCategory>> listLessonCategories({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/lesson-categories', query),
    );
    return Paginated<AdminLessonCategory>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminLessonCategory.fromJson(m),
    );
  }

  /// POST /api/admin/lesson-categories
  Future<void> createLessonCategory(Map<String, dynamic> body) async {
    await _client.post('/api/admin/lesson-categories', body);
  }

  /// PATCH /api/admin/lesson-categories/:id
  Future<void> updateLessonCategory(String id, Map<String, dynamic> body) async {
    await _client.patch('/api/admin/lesson-categories/$id', body);
  }

  /// PATCH /api/admin/lesson-categories/:id/status
  Future<void> updateLessonCategoryStatus(String id, String status) async {
    await _client.patch('/api/admin/lesson-categories/$id/status', {
      'status': status,
    });
  }

  // ── Lessons ──

  /// GET /api/admin/lessons
  Future<Paginated<AdminLesson>> listLessons({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/lessons', query),
    );
    return Paginated<AdminLesson>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminLesson.fromJson(m),
    );
  }

  /// POST /api/admin/lessons
  Future<void> createLesson(Map<String, dynamic> body) async {
    await _client.post('/api/admin/lessons', body);
  }

  /// PATCH /api/admin/lessons/:id
  Future<void> updateLesson(String id, Map<String, dynamic> body) async {
    await _client.patch('/api/admin/lessons/$id', body);
  }

  /// PATCH /api/admin/lessons/:id/status
  Future<void> updateLessonStatus(String id, String status) async {
    await _client.patch('/api/admin/lessons/$id/status', {
      'status': status,
    });
  }

  // ── Chords ──

  /// GET /api/admin/chords
  Future<Paginated<AdminChord>> listChords({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/chords', query),
    );
    return Paginated<AdminChord>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminChord.fromJson(m),
    );
  }

  /// POST /api/admin/chords
  Future<void> createChord(Map<String, dynamic> body) async {
    await _client.post('/api/admin/chords', body);
  }

  /// PATCH /api/admin/chords/:id
  Future<void> updateChord(String id, Map<String, dynamic> body) async {
    await _client.patch('/api/admin/chords/$id', body);
  }

  /// PATCH /api/admin/chords/:id/status
  Future<void> updateChordStatus(String id, String status) async {
    await _client.patch('/api/admin/chords/$id/status', {
      'status': status,
    });
  }

  // ── Scales ──

  /// GET /api/admin/scales
  Future<Paginated<AdminScale>> listScales({
    AdminListQuery query = const AdminListQuery(),
  }) async {
    final response = await _client.get(
      _withQuery('/api/admin/scales', query),
    );
    return Paginated<AdminScale>.fromJson(
      Map<String, dynamic>.from(response as Map),
      (m) => AdminScale.fromJson(m),
    );
  }

  /// POST /api/admin/scales
  Future<void> createScale(Map<String, dynamic> body) async {
    await _client.post('/api/admin/scales', body);
  }

  /// PATCH /api/admin/scales/:id
  Future<void> updateScale(String id, Map<String, dynamic> body) async {
    await _client.patch('/api/admin/scales/$id', body);
  }

  /// PATCH /api/admin/scales/:id/status
  Future<void> updateScaleStatus(String id, String status) async {
    await _client.patch('/api/admin/scales/$id/status', {
      'status': status,
    });
  }
}
