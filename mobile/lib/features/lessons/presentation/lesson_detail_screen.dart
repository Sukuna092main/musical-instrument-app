import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/lesson_api.dart';
import '../../vip/presentation/vip_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late final LessonsApi _api;
  late Future<LessonDetail> _lessonFuture;
  bool _busy = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _api = LessonsApi(ApiClient());
    _lessonFuture = _api.getLesson(widget.slug);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      await action();
      final updatedLesson = await _api.getLesson(widget.slug);

      if (!mounted) return;

      setState(() {
        _lessonFuture = Future.value(updatedLesson);
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _actionError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openVip() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VipScreen()));
    if (!mounted) return;
    setState(() {
      _lessonFuture = _api.getLesson(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<LessonDetail>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final lesson = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (lesson.isVip)
                    Icon(
                      lesson.canAccess
                          ? Icons.workspace_premium_outlined
                          : Icons.lock_outline,
                      color: scheme.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _metadata(lesson),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (!lesson.canAccess)
                _LockedLesson(onUpgrade: _openVip)
              else ...[
                if (lesson.content == null || lesson.content!.trim().isEmpty)
                  const Text('Lesson content is being prepared.')
                else
                  SelectableText(
                    lesson.content!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                const SizedBox(height: 28),
                if (_actionError != null) ...[
                  Text(
                    _actionError!,
                    style: TextStyle(color: scheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                _LessonActionButton(
                  lesson: lesson,
                  busy: _busy,
                  onStart: () {
                    _runAction(() => _api.startLesson(lesson.id));
                  },
                  onComplete: () {
                    _runAction(() => _api.completeLesson(lesson.id));
                  },
                  onReset: () {
                    _runAction(() => _api.resetLesson(lesson.id));
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _metadata(LessonDetail lesson) {
    final values = [
      if (lesson.categoryName != null) lesson.categoryName!,
      if (lesson.instrumentName != null) lesson.instrumentName!,
      _difficultyLabel(lesson.difficulty),
    ];

    return values.join(' | ');
  }

  String _difficultyLabel(String value) {
    if (value.isEmpty) return 'Beginner';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _LockedLesson extends StatelessWidget {
  const _LockedLesson({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 42,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'VIP lesson',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upgrade to VIP to unlock this lesson.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onUpgrade,
            icon: Icon(Icons.workspace_premium),
            label: const Text('Upgrade to VIP'),
          ),
        ],
      ),
    );
  }
}

class _LessonActionButton extends StatelessWidget {
  const _LessonActionButton({
    required this.lesson,
    required this.busy,
    required this.onStart,
    required this.onComplete,
    required this.onReset,
  });

  final LessonDetail lesson;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (lesson.progressStatus == 'completed') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onReset,
          icon: const Icon(Icons.replay_outlined),
          label: const Text('Learn again'),
        ),
      );
    }

    final isInProgress = lesson.progressStatus == 'in_progress';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : (isInProgress ? onComplete : onStart),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isInProgress
                    ? Icons.check_circle_outline
                    : Icons.play_arrow_outlined,
              ),
        label: Text(isInProgress ? 'Mark as completed' : 'Start lesson'),
      ),
    );
  }
}
