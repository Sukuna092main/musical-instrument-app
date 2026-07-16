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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Chord'),
        backgroundColor: const Color(0xFFF7F7F2),
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
                      color: const Color(0xFFB7791F),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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

class _LockedChord extends StatelessWidget {
  const _LockedChord();

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
          Text('VIP chord', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Upgrade to VIP to unlock this chord diagram.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
