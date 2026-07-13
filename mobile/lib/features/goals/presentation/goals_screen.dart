import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/practice_goals_api.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
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
