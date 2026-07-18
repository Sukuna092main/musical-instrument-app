import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/lesson_api.dart';
import 'lesson_detail_screen.dart';
import '../../chords/presentation/chords_screen.dart';
import '../../scales/presentation/scales_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late final LessonsApi _api;
  late Future<_LessonsData> _lessonsFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _api = LessonsApi(ApiClient());
    _lessonsFuture = _loadLessons();
  }

  Future<_LessonsData> _loadLessons() async {
    final categoriesFuture = _api.getCategories();
    final lessonsFuture = _api.getLessons(categoryId: _selectedCategoryId);

    return _LessonsData(
      categories: await categoriesFuture,
      lessons: await lessonsFuture,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _lessonsFuture = _loadLessons();
    });

    await _lessonsFuture;
  }

  void _selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _lessonsFuture = _loadLessons();
    });
  }

  Future<void> _openLesson(LessonSummary lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonDetailScreen(slug: lesson.slug)),
    );

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openChords() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChordsScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openScales() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScalesScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learn),
        actions: [
          TextButton.icon(
            onPressed: _openChords,
            icon: const Icon(Icons.music_note_outlined),
            label: Text(l10n.chords),
          ),
          TextButton.icon(
            onPressed: _openScales,
            icon: const Icon(Icons.graphic_eq),
            label: Text(l10n.scales),
          ),
          IconButton(
            tooltip: l10n.refreshLessons,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_LessonsData>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    l10n.couldNotLoadLessons,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refresh,
                    child: Text(l10n.tryAgain),
                  ),
                ],
              );
            }

            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  l10n.buildYourSkills,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lessonsSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _selectedCategoryId == null,
                        onSelected: (_) => _selectCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...data.categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${category.name} (${category.lessonCount})',
                            ),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) => _selectCategory(category.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (data.lessons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 56,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.noLessonsAvailable),
                      ],
                    ),
                  )
                else
                  ...data.lessons.map(
                    (lesson) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LessonCard(
                        lesson: lesson,
                        onTap: () => _openLesson(lesson),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LessonsData {
  const _LessonsData({required this.categories, required this.lessons});

  final List<LessonCategory> categories;
  final List<LessonSummary> lessons;
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final LessonSummary lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metadata = [
      if (lesson.categoryName != null) lesson.categoryName!,
      if (lesson.instrumentName != null) lesson.instrumentName!,
      _difficultyLabel(lesson.difficulty),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  lesson.progressStatus == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.menu_book_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.join(' | '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    if (lesson.progressStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson.progressStatus == 'completed'
                            ? l10n.completed
                            : l10n.inProgress,
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
              ),
              if (lesson.isVip)
                Tooltip(
                  message: l10n.vipLesson,
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.goldText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _difficultyLabel(String value) {
    if (value.isEmpty) return 'Beginner';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
