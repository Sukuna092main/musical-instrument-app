import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_api.dart';

/// Admin Dashboard — tổng quan revenue, users, subscriptions, payments, instruments.
/// Data: GET /api/admin/dashboard (AdminApi.getDashboard).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApi _api = AdminApi(ApiClient());

  AdminDashboard? _data;
  bool _loading = true;
  String? _error;

  final _vnd = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final d = _data!;
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _RevenueCard(revenue: d.revenue, vnd: _vnd),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _StatCard(
                icon: Icons.people_alt_outlined,
                color: AppColors.accent,
                title: 'Users',
                mainValue: '${d.users.total}',
                lines: [
                  'New today: ${d.users.newToday}',
                  'New 7d: ${d.users.newLast7Days}',
                  'Blocked: ${d.users.blocked}',
                ],
              ),
              _StatCard(
                icon: Icons.workspace_premium_outlined,
                color: AppColors.goldText,
                title: 'Subscriptions',
                mainValue: '${d.subscriptions.active}',
                lines: [
                  'New this month: ${d.subscriptions.newThisMonth}',
                  'Expired: ${d.subscriptions.expired}',
                  'Cancelled: ${d.subscriptions.cancelled}',
                ],
              ),
              _StatCard(
                icon: Icons.payment_outlined,
                color: AppColors.accentDark,
                title: 'Payments',
                mainValue: '${d.payments.success}',
                lines: [
                  'Pending: ${d.payments.pending}',
                  'Refunded: ${d.payments.refunded}',
                  'Failed: ${d.payments.failed}',
                ],
              ),
              _StatCard(
                icon: Icons.piano_outlined,
                color: AppColors.accent,
                title: 'Instruments',
                mainValue: '${d.instruments.total}',
                lines: [
                  'Free: ${d.instruments.free} · VIP: ${d.instruments.vip}',
                  'Active: ${d.instruments.active}',
                  'Hidden: ${d.instruments.hidden}',
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Management',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.people_alt_outlined,
            title: 'Users',
            subtitle: 'Search, block/unblock users',
            onTap: () {
              // TODO: Navigator.push → AdminUsersScreen
            },
          ),
          _NavTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Manual payments',
            subtitle: 'Approve / reject bank transfer requests',
            onTap: () {
              // TODO: Navigator.push → AdminManualPaymentsScreen
            },
          ),
          _NavTile(
            icon: Icons.payment_outlined,
            title: 'Payments',
            subtitle: 'Payment history by provider',
            onTap: () {
              // TODO: Navigator.push → AdminPaymentsScreen
            },
          ),
          _NavTile(
            icon: Icons.card_membership_outlined,
            title: 'Subscriptions',
            subtitle: 'Active / expired subscriptions',
            onTap: () {
              // TODO: Navigator.push → AdminSubscriptionsScreen
            },
          ),
          _NavTile(
            icon: Icons.workspace_premium_outlined,
            title: 'VIP plans',
            subtitle: 'Edit pricing, features, status',
            onTap: () {
              // TODO: Navigator.push → AdminVipPlansScreen
            },
          ),
          _NavTile(
            icon: Icons.piano_outlined,
            title: 'Instruments',
            subtitle: 'CRUD instruments, VIP flag, tags',
            onTap: () {
              // TODO: Navigator.push → AdminInstrumentsScreen
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Revenue card (big, top)
// ─────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenue, required this.vnd});

  final AdminRevenue revenue;
  final NumberFormat vnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net revenue',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${vnd.format(revenue.netTotal)} ₫',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gross ${vnd.format(revenue.grossTotal)} ₫  ·  Refunded ${vnd.format(revenue.refundedTotal)} ₫',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RevenuePeriod(label: 'Today', value: revenue.today, vnd: vnd),
              _RevenuePeriod(
                label: '7 days',
                value: revenue.last7Days,
                vnd: vnd,
              ),
              _RevenuePeriod(
                label: '30 days',
                value: revenue.last30Days,
                vnd: vnd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenuePeriod extends StatelessWidget {
  const _RevenuePeriod({
    required this.label,
    required this.value,
    required this.vnd,
  });

  final String label;
  final int value;
  final NumberFormat vnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            '${vnd.format(value)} ₫',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat card (grid 2x2)
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.mainValue,
    required this.lines,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String mainValue;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mainValue,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            for (final line in lines)
              Text(
                line,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Navigation tile
// ─────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
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
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentSurface,
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: onTap,
      ),
    );
  }
}
