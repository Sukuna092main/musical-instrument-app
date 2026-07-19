import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/network/api_client.dart';
import '../data/lesson_api.dart';
import 'lesson_detail_screen.dart';

class LearningProgressScreen extends StatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  late final LessonsApi _api;
  late Future<LessonProgressData> _progressFuture;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _api = LessonsApi(ApiClient());
    _progressFuture = _api.getLearningProgress();
  }

  Future<void> _refresh() async {
    setState(() {
      _progressFuture = _api.getLearningProgress();
    });

    await _progressFuture;
  }

  Future<void> _openLesson(LessonProgressItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonDetailScreen(slug: item.slug)),
    );

    if (mounted) {
      await _refresh();
    }
  }

  void _selectStatus(String? status) {
    setState(() => _selectedStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learningProgress),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.refreshLessons,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<LessonProgressData>(
          future: _progressFuture,
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
                    l10n.couldNotLoad(l10n.learningProgress),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _refresh, child: Text(l10n.tryAgain)),
                ],
              );
            }

            final data = snapshot.data!;
            final items = _selectedStatus == null
                ? data.items
                : data.items
                      .where((item) => item.status == _selectedStatus)
                      .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProgressStat(
                        value: data.total.toString(),
                        label: l10n.totalLessons(data.total),
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressStat(
                        value: data.inProgress.toString(),
                        label: l10n.inProgressLessons(data.inProgress),
                        color: scheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressStat(
                        value: data.completed.toString(),
                        label: l10n.completedLessons(data.completed),
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: _selectedStatus == null,
                      onSelected: (_) => _selectStatus(null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.inProgress),
                      selected: _selectedStatus == 'in_progress',
                      onSelected: (_) => _selectStatus('in_progress'),
                    ),
                    ChoiceChip(
                      label: Text(l10n.completed),
                      selected: _selectedStatus == 'completed',
                      onSelected: (_) => _selectStatus('completed'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  _EmptyProgressView(status: _selectedStatus)
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LessonProgressCard(
                        item: item,
                        onTap: () => _openLesson(item),
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

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonProgressCard extends StatelessWidget {
  const _LessonProgressCard({required this.item, required this.onTap});

  final LessonProgressItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompleted = item.status == 'completed';

    final metadata = [
      if (item.categoryName != null) item.categoryName!,
      if (item.instrumentName != null) item.instrumentName!,
      _capitalize(item.difficulty),
    ];

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? scheme.primaryContainer
                      : scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline
                      : Icons.play_circle_outline,
                  color: isCompleted
                      ? scheme.onPrimaryContainer
                      : scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCompleted
                          ? item.completedAt == null
                                ? l10n.completed
                                : l10n.completedOn(
                                    _formatDate(item.completedAt!),
                                  )
                          : l10n.inProgress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCompleted ? scheme.primary : scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _EmptyProgressView extends StatelessWidget {
  const _EmptyProgressView({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final message = switch (status) {
      'in_progress' => l10n.noInProgressLessons,
      'completed' => l10n.noCompletedLessons,
      _ => l10n.noLearningProgress,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(Icons.auto_graph_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.startLessonToTrackProgress,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
