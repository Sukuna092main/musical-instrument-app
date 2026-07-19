import '../../../core/network/api_client.dart';

class LessonCategory {
  const LessonCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.lessonCount,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final int lessonCount;

  factory LessonCategory.fromJson(Map<String, dynamic> json) {
    final count = _asMap(json['_count']);

    return LessonCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      lessonCount: _toInt(count?['lessons']),
    );
  }
}

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.difficulty,
    required this.isVip,
    required this.categoryName,
    required this.instrumentName,
    required this.progressStatus,
  });

  final String id;
  final String title;
  final String slug;
  final String difficulty;
  final bool isVip;
  final String? categoryName;
  final String? instrumentName;
  final String? progressStatus;

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    final category = _asMap(json['lesson_categories']);
    final instrument = _asMap(json['instruments']);
    final progress = _asMap(json['userProgress']);

    return LessonSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isVip: json['is_vip'] == true,
      categoryName: category?['name'] as String?,
      instrumentName: instrument?['name'] as String?,
      progressStatus: progress?['status'] as String?,
    );
  }
}

class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.difficulty,
    required this.isVip,
    required this.canAccess,
    required this.content,
    required this.categoryName,
    required this.instrumentName,
    required this.progressStatus,
  });

  final String id;
  final String title;
  final String slug;
  final String difficulty;
  final bool isVip;
  final bool canAccess;
  final String? content;
  final String? categoryName;
  final String? instrumentName;
  final String? progressStatus;

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    final category = _asMap(json['category']);
    final instrument = _asMap(json['instrument']);
    final progress = _asMap(json['userProgress']);

    return LessonDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isVip: json['is_vip'] == true,
      canAccess: json['canAccess'] == true,
      content: json['content'] as String?,
      categoryName: category?['name'] as String?,
      instrumentName: instrument?['name'] as String?,
      progressStatus: progress?['status'] as String?,
    );
  }
}

class LessonProgressData {
  const LessonProgressData({
    required this.items,
    required this.total,
    required this.completed,
    required this.inProgress,
  });

  final List<LessonProgressItem> items;
  final int total;
  final int completed;
  final int inProgress;

  factory LessonProgressData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']) ?? <String, dynamic>{};
    final items = json['items'] as List<dynamic>? ?? [];

    return LessonProgressData(
      items: items
          .map(
            (item) => LessonProgressItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      total: _toInt(summary['total']),
      completed: _toInt(summary['completed']),
      inProgress: _toInt(summary['inProgress']),
    );
  }
}

class LessonProgressItem {
  const LessonProgressItem({
    required this.lessonId,
    required this.title,
    required this.slug,
    required this.status,
    required this.difficulty,
    required this.isVip,
    required this.categoryName,
    required this.instrumentName,
    required this.completedAt,
  });

  final String lessonId;
  final String title;
  final String slug;
  final String status;
  final String difficulty;
  final bool isVip;
  final String? categoryName;
  final String? instrumentName;
  final DateTime? completedAt;

  factory LessonProgressItem.fromJson(Map<String, dynamic> json) {
    final lesson = _asMap(json['lessons']) ?? <String, dynamic>{};
    final category = _asMap(lesson['lesson_categories']);
    final instrument = _asMap(lesson['instruments']);

    return LessonProgressItem(
      lessonId: lesson['id'] as String? ?? json['lesson_id'] as String,
      title: lesson['title'] as String? ?? 'Lesson',
      slug: lesson['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'in_progress',
      difficulty: lesson['difficulty'] as String? ?? 'beginner',
      isVip: lesson['is_vip'] == true,
      categoryName: category?['name'] as String?,
      instrumentName: instrument?['name'] as String?,
      completedAt: _dateFromJson(json['completed_at']),
    );
  }
}

class LessonsApi {
  LessonsApi(this._client);

  final ApiClient _client;

  Future<List<LessonCategory>> getCategories() async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/lessons/categories') as Map,
    );

    final data = response['data'];
    if (data is! List) return [];

    return data
        .map(
          (item) =>
              LessonCategory.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<LessonSummary>> getLessons({
    String? categoryId,
    bool? isVip,
  }) async {
    final query = <String, String>{
      'limit': '50',
      'categoryId': ?categoryId,
      if (isVip != null) 'isVip': isVip.toString(),
    };

    final queryString = Uri(queryParameters: query).query;
    final response = Map<String, dynamic>.from(
      await _client.get('/api/lessons?$queryString') as Map,
    );

    final items = response['items'];
    if (items is! List) return [];

    return items
        .map(
          (item) =>
              LessonSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<LessonDetail> getLesson(String slug) async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/lessons/${Uri.encodeComponent(slug)}') as Map,
    );

    return LessonDetail.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<LessonProgressData> getLearningProgress() async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/user-lesson-progress') as Map,
    );

    return LessonProgressData.fromJson(response);
  }

  Future<void> startLesson(String lessonId) async {
    await _client.post('/api/user-lesson-progress/$lessonId/start', {});
  }

  Future<void> completeLesson(String lessonId) async {
    await _client.post('/api/user-lesson-progress/$lessonId/complete', {});
  }

  Future<void> resetLesson(String lessonId) async {
    await _client.post('/api/user-lesson-progress/$lessonId/reset', {});
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateFromJson(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
