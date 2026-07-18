import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../practice/data/practice_api.dart';
import '../../practice/presentation/practice_history_screen.dart';
import '../../practice/presentation/practice_timer_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../lessons/presentation/lesson_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../instruments/presentation/instruments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth});

  final AuthResult auth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PracticeApi _practiceApi;
  late Future<PracticeDashboard> _dashboardFuture;
  late AuthUser _currentUser;

  @override
  void initState() {
    super.initState();
    _practiceApi = PracticeApi(ApiClient());
    _dashboardFuture = _practiceApi.getDashboard();
    _currentUser = widget.auth.user;
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

  Future<void> _openGoals() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openLessons() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LessonsScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openInstruments() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstrumentsScreen()));

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.logOutQuestion),
              content: Text(l10n.logOutConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.logOut),
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceDashboard),
        actions: [
          IconButton(
            tooltip: l10n.support,
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
            },
          ),
          IconButton(
            tooltip: l10n.logOut,
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            tooltip: l10n.profile,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: _currentUser),
                ),
              );
              // Khi quay về Home, re-fetch user mới nhất từ server.
              if (!mounted) return;
              try {
                final fresh = await AuthApi().getMe();
                if (mounted) setState(() => _currentUser = fresh);
              } catch (_) {
                // Token hết hạn hoặc lỗi mạng — giữ nguyên user cũ.
              }
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
                    l10n.couldNotLoad(l10n.practiceDashboard.toLowerCase()),
                    style: Theme.of(context).textTheme.titleLarge,
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

            final dashboard = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.hi(_currentUser.fullName),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.readyForToday,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                _StatsGrid(dashboard: dashboard),
                const SizedBox(height: 16),
                _ActiveSessionCard(session: dashboard.activeSession),
                const SizedBox(height: 16),
                _ActionCard(
                  icon: Icons.timer_outlined,
                  title: l10n.practiceTimer,
                  subtitle: l10n.practiceTimerSubtitle,
                  onTap: _openPracticeTimer,
                ),
                _ActionCard(
                  icon: Icons.history_outlined,
                  title: l10n.practiceHistory,
                  subtitle: l10n.practiceHistorySubtitle,
                  onTap: _openPracticeHistory,
                ),
                _ActionCard(
                  icon: Icons.flag_outlined,
                  title: l10n.goals,
                  subtitle: l10n.goalsSubtitle,
                  onTap: _openGoals,
                ),
                _ActionCard(
                  icon: Icons.menu_book_outlined,
                  title: l10n.learn,
                  subtitle: l10n.learnSubtitle,
                  onTap: _openLessons,
                ),
                _ActionCard(
                  icon: Icons.music_note_outlined,
                  title: l10n.myInstruments,
                  subtitle: l10n.myInstrumentsSubtitle,
                  onTap: _openInstruments,
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
    final l10n = context.l10n;
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
          label: l10n.today,
          value: '${stats.todayMinutes}m',
          helper: l10n.sessions(stats.todaySessions),
          icon: Icons.today_outlined,
        ),
        _StatTile(
          label: l10n.thisWeek,
          value: '${stats.weekMinutes}m',
          helper: l10n.sessions(stats.weekSessions),
          icon: Icons.calendar_view_week_outlined,
        ),
        _StatTile(
          label: l10n.streak,
          value: '${streak.currentStreak}',
          helper: l10n.bestDays(streak.longestStreak),
          icon: Icons.local_fire_department_outlined,
        ),
        _StatTile(
          label: l10n.allTime,
          value: '${stats.allTimeSessions}',
          helper: l10n.completedSessions(stats.allTimeSessions),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
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
    final l10n = context.l10n;
    final hasSession = session != null;
    final scheme = Theme.of(context).colorScheme;

    final backgroundColor = hasSession
        ? scheme.primary
        : scheme.primaryContainer;

    final foregroundColor = hasSession
        ? scheme.onPrimary
        : scheme.onPrimaryContainer;

    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(
          hasSession ? Icons.play_circle_outline : Icons.music_note_outlined,
          color: foregroundColor,
        ),
        title: Text(
          hasSession ? l10n.practiceInProgress : l10n.noActivePractice,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          hasSession
              ? '${session!.instrumentName} • ${_formatTime(session!.startedAt)}'
              : l10n.startWhenReady,
          style: TextStyle(color: foregroundColor.withValues(alpha: 0.8)),
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
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
