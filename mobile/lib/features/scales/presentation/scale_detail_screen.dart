import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/scale_api.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Scale'),
        backgroundColor: const Color(0xFFF7F7F2),
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
                      color: const Color(0xFFB7791F),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _metadata(scale),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              if (!scale.canAccess)
                const _LockedScale()
              else ...[
                _ScaleDiagram(url: scale.diagramUrl),
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

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
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
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFE7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.music_note_outlined,
            size: 56,
            color: Color(0xFF1F7A5A),
          ),
        ),
      ),
    );
  }
}

class _LockedScale extends StatelessWidget {
  const _LockedScale();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 42,
            color: Color(0xFFB7791F),
          ),
          SizedBox(height: 12),
          Text('VIP scale', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Upgrade to VIP to unlock this scale diagram.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
