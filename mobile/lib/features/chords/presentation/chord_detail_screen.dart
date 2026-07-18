import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/chord_api.dart';
import '../../../shared/widgets/audio_player_bar.dart';

class ChordDetailScreen extends StatefulWidget {
  const ChordDetailScreen({super.key, required this.chordId});

  final String chordId;

  @override
  State<ChordDetailScreen> createState() => _ChordDetailScreenState();
}

class _ChordDetailScreenState extends State<ChordDetailScreen> {
  late final ChordsApi _api;
  late Future<ChordDetail> _chordFuture;

  @override
  void initState() {
    super.initState();
    _api = ChordsApi(ApiClient());
    _chordFuture = _api.getChord(widget.chordId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chord'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<ChordDetail>(
        future: _chordFuture,
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

          final chord = snapshot.data!;
          final title = chord.symbol ?? chord.name ?? 'Chord';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (chord.isVip)
                    Icon(
                      chord.canAccess
                          ? Icons.workspace_premium_outlined
                          : Icons.lock_outline,
                      color: scheme.tertiary,
                    ),
                ],
              ),
              if (chord.name != null && chord.name != title) ...[
                const SizedBox(height: 4),
                Text(
                  chord.name!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _metadata(chord),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (!chord.canAccess)
                const _LockedChord()
              else ...[
                _ChordDiagram(url: chord.diagramUrl),
                if (chord.audioUrl != null &&
                    chord.audioUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AudioPlayerBar(audioUrl: chord.audioUrl!),
                ],
                if (chord.description != null &&
                    chord.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'About this chord',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chord.description!,
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

  String _metadata(ChordDetail chord) {
    final values = [
      if (chord.instrumentName != null) chord.instrumentName!,
      _capitalize(chord.category),
      _capitalize(chord.difficulty),
    ];

    return values.join(' | ');
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ChordDiagram extends StatelessWidget {
  const _ChordDiagram({required this.url});

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

class _LockedChord extends StatelessWidget {
  const _LockedChord();

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
            'VIP chord',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onTertiaryContainer,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Upgrade to VIP to unlock this chord diagram.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
