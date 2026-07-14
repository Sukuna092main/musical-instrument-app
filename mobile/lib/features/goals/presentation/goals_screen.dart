import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/practice_goals_api.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final PracticeGoalProgress goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progressValue = goal.progress.clamp(0, 100).toDouble() / 100;
    final unit = GoalType.unit(goal.goalType);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(goal.goalType), color: const Color(0xFF1F7A5A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GoalType.label(goal.goalType),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E7DF),
              color: goal.completed
                  ? const Color(0xFF1F7A5A)
                  : const Color(0xFFB7791F),
            ),
            const SizedBox(height: 10),
            Text(
              '${goal.currentValue}/${goal.targetValue} $unit - ${goal.progress.clamp(0, 100)}%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            if (goal.instrumentName != null) ...[
              const SizedBox(height: 4),
              Text(
                goal.instrumentName!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case GoalType.dailyMinutes:
        return Icons.today_outlined;
      case GoalType.weeklyMinutes:
        return Icons.calendar_view_week_outlined;
      case GoalType.weeklyDays:
        return Icons.event_available_outlined;
      case GoalType.streakDays:
        return Icons.local_fire_department_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({required this.api, this.goal});

  final PracticeGoalsApi api;
  final PracticeGoalProgress? goal;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late String _goalType;
  late final TextEditingController _targetController;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _goalType = widget.goal?.goalType ?? GoalType.dailyMinutes;
    _targetController = TextEditingController(
      text: (widget.goal?.targetValue ?? GoalType.defaultTarget(_goalType))
          .toString(),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = int.tryParse(_targetController.text.trim());

    if (target == null || target <= 0) {
      setState(() {
        _error = 'Target must be greater than 0';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await widget.api.updateGoal(
          goalId: widget.goal!.id,
          goalType: _goalType,
          targetValue: target,
        );
      } else {
        await widget.api.createGoal(goalType: _goalType, targetValue: target);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit goal' : 'Add goal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: const InputDecoration(labelText: 'Goal type'),
              items: GoalType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(GoalType.label(type)),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _goalType = value;
                        _targetController.text = GoalType.defaultTarget(
                          value,
                        ).toString();
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target',
                suffixText: GoalType.unit(_goalType),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEditing ? 'Save changes' : 'Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final PracticeGoalsApi _api;
  late Future<List<PracticeGoalProgress>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _api = PracticeGoalsApi(ApiClient());
    _goalsFuture = _api.getProgress();
  }

  Future<void> _refresh() async {
    setState(() {
      _goalsFuture = _api.getProgress();
    });

    await _goalsFuture;
  }

  Future<void> _openGoalSheet({PracticeGoalProgress? goal}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoalFormSheet(api: _api, goal: goal),
    );

    if (saved == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteGoal(PracticeGoalProgress goal) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete goal?'),
              content: Text(GoalType.label(goal.goalType)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _api.deleteGoal(goal.id);
      if (mounted) {
        await _refresh();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: 'Add goal',
            icon: const Icon(Icons.add),
            onPressed: () => _openGoalSheet(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PracticeGoalProgress>>(
          future: _goalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Could not load goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ],
              );
            }

            final goals = snapshot.data ?? [];

            if (goals.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.flag_outlined,
                    size: 56,
                    color: Color(0xFF1F7A5A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openGoalSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add goal'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalCard(
                  goal: goal,
                  onEdit: () => _openGoalSheet(goal: goal),
                  onDelete: () => _deleteGoal(goal),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
