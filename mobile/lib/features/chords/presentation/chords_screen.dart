import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/chord_api.dart';
import 'chord_detail_screen.dart';

class ChordsScreen extends StatefulWidget {
  const ChordsScreen({super.key});

  @override
  State<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends State<ChordsScreen> {
  late final ChordsApi _api;
  late Future<List<ChordSummary>> _chordsFuture;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _api = ChordsApi(ApiClient());
    _chordsFuture = _api.getChords();
  }

  Future<void> _refresh() async {
    setState(() {
      _chordsFuture = _api.getChords();
    });

    await _chordsFuture;
  }

  Future<void> _openChord(ChordSummary chord) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChordDetailScreen(chordId: chord.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Chords'),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: 'Refresh chords',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ChordSummary>>(
          future: _chordsFuture,
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
                    'Could not load chords',
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

            final chords = snapshot.data ?? [];
            final categories = chords.map((chord) => chord.category).toSet()
              ..removeWhere((category) => category.isEmpty);

            final sortedCategories = categories.toList()..sort();

            final filteredChords = _selectedCategory == null
                ? chords
                : chords
                      .where((chord) => chord.category == _selectedCategory)
                      .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Chord library',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find shapes and theory for the chords you are learning.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...sortedCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_capitalize(category)),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (filteredChords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Column(
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 56,
                          color: Color(0xFF1F7A5A),
                        ),
                        SizedBox(height: 12),
                        Text('No chords available yet'),
                      ],
                    ),
                  )
                else
                  ...filteredChords.map(
                    (chord) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChordCard(
                        chord: chord,
                        onTap: () => _openChord(chord),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ChordCard extends StatelessWidget {
  const _ChordCard({required this.chord, required this.onTap});

  final ChordSummary chord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = chord.symbol ?? chord.name ?? 'Chord';
    final metadata = [
      if (chord.instrumentName != null) chord.instrumentName!,
      _capitalize(chord.category),
      _capitalize(chord.difficulty),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F7A5A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chord.name ?? title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.join(' | '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (chord.isVip)
                const Tooltip(
                  message: 'VIP chord',
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFB7791F),
                  ),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
