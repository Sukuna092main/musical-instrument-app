import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_api.dart';
import '../../practice/data/practice_api.dart';
import '../../practice/presentation/practice_timer_screen.dart';
import '../../practice/presentation/practice_history_screen.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth});

  final AuthResult auth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PracticeApi _practiceApi;
  late Future<PracticeDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _practiceApi = PracticeApi(ApiClient());
    _dashboardFuture = _practiceApi.getDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _practiceApi.getDashboard();
    });

    await _dashboardFuture;
  }

  Future<void> _openPracticeTimer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeTimerScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openPracticeHistory() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeHistoryScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _logout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Log out?'),
              content: const Text(
                'You will need to sign in again to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Log out'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) {
      return;
    }

    await AuthApi().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Practice Dashboard'),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: widget.auth.user),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<PracticeDashboard>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Could not load dashboard',
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

            final dashboard = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Hi, ${widget.auth.user.fullName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for today\'s practice?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                _StatsGrid(dashboard: dashboard),
                const SizedBox(height: 16),
                _ActiveSessionCard(session: dashboard.activeSession),
                const SizedBox(height: 16),
                _ActionCard(
                  icon: Icons.timer_outlined,
                  title: 'Practice timer',
                  subtitle: 'Start a focused session with notes and mood',
                  onTap: () {
                    _openPracticeTimer();
                  },
                ),
                _ActionCard(
                  icon: Icons.history_outlined,
                  title: 'Practice history',
                  subtitle: 'Review completed sessions, notes, and mood',
                  onTap: () {
                    _openPracticeHistory();
                  },
                ),
                _ActionCard(
                  icon: Icons.flag_outlined,
                  title: 'Goals',
                  subtitle: 'Track daily minutes, weekly days, and streaks',
                  onTap: () {},
                ),
                _ActionCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Learn',
                  subtitle: 'Browse lessons, chords, and scales',
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.dashboard});

  final PracticeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final stats = dashboard.stats;
    final streak = dashboard.streak;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatTile(
          label: 'Today',
          value: '${stats.todayMinutes}m',
          helper: '${stats.todaySessions} sessions',
          icon: Icons.today_outlined,
        ),
        _StatTile(
          label: 'This week',
          value: '${stats.weekMinutes}m',
          helper: '${stats.weekSessions} sessions',
          icon: Icons.calendar_view_week_outlined,
        ),
        _StatTile(
          label: 'Streak',
          value: '${streak.currentStreak} days',
          helper: 'Best ${streak.longestStreak} days',
          icon: Icons.local_fire_department_outlined,
        ),
        _StatTile(
          label: 'All time',
          value: '${stats.allTimeSessions}',
          helper: 'completed sessions',
          icon: Icons.history_outlined,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1F7A5A)),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label),
            Text(
              helper,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});

  final ActivePracticeSession? session;

  @override
  Widget build(BuildContext context) {
    final hasSession = session != null;

    return Card(
      elevation: 0,
      color: hasSession ? const Color(0xFF163B32) : const Color(0xFFE8EFE7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(
          hasSession ? Icons.play_circle_outline : Icons.music_note_outlined,
          color: hasSession ? Colors.white : const Color(0xFF1F7A5A),
        ),
        title: Text(
          hasSession ? 'Practice in progress' : 'No active practice',
          style: TextStyle(
            color: hasSession ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          hasSession
              ? '${session!.instrumentName} started at ${_formatTime(session!.startedAt)}'
              : 'Start a timer when you are ready',
          style: TextStyle(color: hasSession ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F7A5A)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
