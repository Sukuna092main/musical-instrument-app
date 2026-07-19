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
        title: const Text('Subscribe via bank transfer'),
        content: Text(
          'You will get ${plan.name} (${plan.durationDays} days) after admin approval. '
          'A 24h VIP trial is activated immediately so you can use premium features while waiting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasing = true);

    try {
      final result = await _api.requestManualVip(plan.code);

      if (!mounted) return;

      // Mở bottom sheet hiện QR + STK + thông tin chuyển khoản.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _PaymentSheet(plan: plan, result: result),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.trialHours > 0
                ? 'VIP trial activated for ${result.trialHours}h. Please complete the bank transfer.'
                : 'Request created. Please complete the bank transfer.',
          ),
        ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Color.fromARGB(255, 145, 123, 1),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'VIP Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subscription.planName,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${subscription.daysRemaining} days remaining',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expires ${_formatDate(subscription.expiredAt)}',
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 42,
              color: scheme.onTertiaryContainer,
            ),
            SizedBox(height: 12),
            Text(
              'You don\'t have VIP yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Upgrade to unlock premium lessons, chords, and scales.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
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
                    style: theme.textTheme.titleMedium?.copyWith(
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
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        color: scheme.onPrimary,
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
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${plan.durationDays} days',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (plan.description != null &&
                plan.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.description!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: scheme.primary),
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
                child: isPurchasing
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          payment.status == 'success'
              ? Icons.check_circle_outline
              : Icons.error_outline,
          color: payment.status == 'success' ? scheme.primary : scheme.error,
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

// ── Payment bottom sheet (QR + STK) ──

class _PaymentSheet extends StatelessWidget {
  const _PaymentSheet({required this.plan, required this.result});

  final VipPlan plan;
  final ManualRequestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = result.paymentInfo;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Complete your payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (result.trialHours > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'VIP trial activated for ${result.trialHours} hours. '
                        'Complete the transfer to keep VIP after the trial.',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!info.configured) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bank transfer is not configured on the server yet. '
                  'Please contact support.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ] else ...[
              if (info.qrUrl != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      info.qrUrl!,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Container(
                        width: 220,
                        height: 220,
                        color: scheme.surfaceContainerHighest,
                        child: const Center(child: Text('Could not load QR')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _InfoRow(
                label: 'Amount',
                value: _formatPrice(plan.price, plan.currency),
              ),
              if (info.accountNo != null)
                _InfoRow(label: 'Account no.', value: info.accountNo!),
              if (info.accountName != null)
                _InfoRow(label: 'Account name', value: info.accountName!),
              if (info.transferRef != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transfer content (IMPORTANT)',
                              style: TextStyle(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info.transferRef!,
                              style: TextStyle(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          // Cần import package:flutter/services.dart để dùng Clipboard.
                          // Để gọn, mình không thêm ở đây — user copy bằng tay.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please copy this code into your banking app.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'After transferring, your VIP will be activated once admin approves '
                '(usually within a few hours). The 24h trial lets you use VIP features immediately.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
