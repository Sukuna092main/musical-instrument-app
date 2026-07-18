import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/scale_api.dart';
import '../../vip/presentation/vip_screen.dart';
import '../../../shared/widgets/audio_player_bar.dart';

class ScaleDetailScreen extends StatefulWidget {
  const ScaleDetailScreen({super.key, required this.scaleId});

  final String scaleId;

  @override
  State<ScaleDetailScreen> createState() => _ScaleDetailScreenState();
}

class _ScaleDetailScreenState extends State<ScaleDetailScreen> {
  late final ScalesApi _api;
  late Future<ScaleDetail> _scaleFuture;

  @override
  void initState() {
    super.initState();
    _api = ScalesApi(ApiClient());
    _scaleFuture = _api.getScale(widget.scaleId);
  }

  Future<void> _openVip() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VipScreen()));
    if (!mounted) return;
    setState(() {
      _scaleFuture = _api.getScale(widget.scaleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scale'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<ScaleDetail>(
        future: _scaleFuture,
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

          final scale = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      scale.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (scale.isVip)
                    Icon(
                      scale.canAccess
                          ? Icons.workspace_premium_outlined
                          : Icons.lock_outline,
                      color: scheme.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _metadata(scale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (!scale.canAccess)
                _LockedScale(onUpgrade: _openVip)
              else ...[
                _ScaleDiagram(url: scale.diagramUrl),
                if (scale.audioUrl != null &&
                    scale.audioUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AudioPlayerBar(audioUrl: scale.audioUrl!),
                ],
                if (scale.description != null &&
                    scale.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'About this scale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scale.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  String _metadata(ScaleDetail scale) {
    final values = [
      if (scale.key != null) scale.key!,
      if (scale.instrumentName != null) scale.instrumentName!,
      _capitalize(scale.scaleType),
      _capitalize(scale.difficulty),
    ];

    return values.join(' | ');
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ScaleDiagram extends StatelessWidget {
  const _ScaleDiagram({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const _DiagramPlaceholder();
    }

    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _DiagramPlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _DiagramPlaceholder extends StatelessWidget {
  const _DiagramPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.music_note_outlined,
            size: 56,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _LockedScale extends StatelessWidget {
  const _LockedScale({required this.onUpgrade});

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
          SizedBox(height: 12),
          Text(
            'VIP scale',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onTertiaryContainer,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Upgrade to VIP to unlock this scale diagram.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Upgrade to VIP'),
          ),
        ],
      ),
    );
  }
}
