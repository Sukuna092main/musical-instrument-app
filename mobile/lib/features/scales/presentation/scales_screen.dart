import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/scale_api.dart';
import 'scale_detail_screen.dart';

class ScalesScreen extends StatefulWidget {
  const ScalesScreen({super.key});

  @override
  State<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> {
  late final ScalesApi _api;
  late Future<List<ScaleSummary>> _scalesFuture;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _api = ScalesApi(ApiClient());
    _scalesFuture = _api.getScales();
  }

  Future<void> _refresh() async {
    setState(() {
      _scalesFuture = _api.getScales(scaleType: _selectedType);
    });

    await _scalesFuture;
  }

  void _selectType(String? type) {
    if (_selectedType == type) return;

    setState(() {
      _selectedType = type;
      _scalesFuture = _api.getScales(scaleType: type);
    });
  }

  Future<void> _openScale(ScaleSummary scale) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScaleDetailScreen(scaleId: scale.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Scales'),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: 'Refresh scales',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ScaleSummary>>(
          future: _scalesFuture,
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
                    'Could not load scales',
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

            final scales = snapshot.data ?? [];
            final types = scales.map((s) => s.scaleType).toSet()
              ..removeWhere((t) => t.isEmpty);

            final sortedTypes = types.toList()..sort();

            final filteredScales = _selectedType == null
                ? scales
                : scales.where((s) => s.scaleType == _selectedType).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Scale library',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore scales for the instruments you are learning.',
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
                        selected: _selectedType == null,
                        onSelected: (_) => _selectType(null),
                      ),
                      const SizedBox(width: 8),
                      ...sortedTypes.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_capitalize(type)),
                            selected: _selectedType == type,
                            onSelected: (_) => _selectType(type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (filteredScales.isEmpty)
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
                        Text('No scales available yet'),
                      ],
                    ),
                  )
                else
                  ...filteredScales.map(
                    (scale) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScaleCard(
                        scale: scale,
                        onTap: () => _openScale(scale),
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

class _ScaleCard extends StatelessWidget {
  const _ScaleCard({required this.scale, required this.onTap});

  final ScaleSummary scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (scale.key != null) scale.key!,
      if (scale.instrumentName != null) scale.instrumentName!,
      _capitalize(scale.scaleType),
      _capitalize(scale.difficulty),
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
                child: const Icon(Icons.graphic_eq, color: Color(0xFF1F7A5A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scale.name,
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
              if (scale.isVip)
                const Tooltip(
                  message: 'VIP scale',
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
