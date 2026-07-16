import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/vip_api.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  late final VipApi _api;
  late Future<_VipData> _dataFuture;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _api = VipApi(ApiClient());
    _dataFuture = _loadData();
  }

  Future<_VipData> _loadData() async {
    final plansFuture = _api.getPlans();
    final subFuture = _api.getMySubscription();
    final historyFuture = _api.getPaymentHistory();

    return _VipData(
      plans: await plansFuture,
      subscription: await subFuture,
      payments: await historyFuture,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  Future<void> _purchase(VipPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text(
          'Subscribe to ${plan.name} for ${_formatPrice(plan.price, plan.currency)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasing = true);

    try {
      await _api.devPurchase(plan.code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VIP activated successfully!')),
      );

      await _refresh();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('VIP'),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_VipData>(
          future: _dataFuture,
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
                    'Could not load VIP info',
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

            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Active subscription ──
                if (data.subscription != null && data.subscription!.isActive)
                  _ActiveSubscriptionCard(subscription: data.subscription!)
                else
                  const _NoSubscriptionCard(),

                const SizedBox(height: 24),

                // ── Plans ──
                Text(
                  'Available plans',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...data.plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: plan,
                      isCurrentPlan:
                          data.subscription?.isActive == true &&
                          data.subscription!.planCode == plan.code,
                      isPurchasing: _isPurchasing,
                      onPurchase: () => _purchase(plan),
                    ),
                  ),
                ),

                if (data.plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('No plans available')),
                  ),

                // ── Payment history ──
                if (data.payments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Payment history',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data.payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PaymentTile(payment: payment),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Data holder ──

class _VipData {
  const _VipData({
    required this.plans,
    required this.subscription,
    required this.payments,
  });

  final List<VipPlan> plans;
  final VipSubscription? subscription;
  final List<PaymentRecord> payments;
}

// ── Active subscription card ──

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.subscription});

  final VipSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF163B32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'VIP Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subscription.planName,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${subscription.daysRemaining} days remaining',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expires ${_formatDate(subscription.expiredAt)}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No subscription card ──

class _NoSubscriptionCard extends StatelessWidget {
  const _NoSubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF4DE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 42,
              color: Color(0xFFB7791F),
            ),
            SizedBox(height: 12),
            Text(
              'You don\'t have VIP yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Upgrade to unlock premium lessons, chords, and scales.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan card ──

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isPurchasing,
    required this.onPurchase,
  });

  final VipPlan plan;
  final bool isCurrentPlan;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F7A5A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatPrice(plan.price, plan.currency),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F7A5A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${plan.durationDays} days',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            if (plan.description != null &&
                plan.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description!, style: const TextStyle(height: 1.4)),
            ],
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF1F7A5A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCurrentPlan || isPurchasing ? null : onPurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A5A),
                  disabledBackgroundColor: const Color(0xFFCCDDCC),
                ),
                child: isPurchasing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isCurrentPlan ? 'Active' : 'Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment tile ──

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          payment.status == 'success'
              ? Icons.check_circle_outline
              : Icons.error_outline,
          color: payment.status == 'success'
              ? const Color(0xFF1F7A5A)
              : Colors.red,
        ),
        title: Text(payment.planName),
        subtitle: Text(_formatDate(payment.createdAt)),
        trailing: Text(
          _formatPrice(payment.amount, payment.currency),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Helpers ──

String _formatPrice(int amount, String currency) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$formatted $currency';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  return '$day/$month/$year';
}
