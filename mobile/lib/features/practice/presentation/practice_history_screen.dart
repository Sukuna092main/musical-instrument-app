import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/practice_history_api.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  final PracticeHistoryApi _api = PracticeHistoryApi(ApiClient());
  final ScrollController _scrollController = ScrollController();

  final List<PracticeHistorySession> _sessions = [];
  List<PracticeHistoryInstrument> _instruments = [];

  String? _selectedInstrumentId;
  String? _error;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
    _loadInstruments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 250) {
      _loadPage(reset: false);
    }
  }

  Future<void> _loadInstruments() async {
    try {
      final instruments = await _api.getUserInstruments();

      if (!mounted) return;

      setState(() {
        _instruments = instruments;
      });
    } catch (_) {
      // History remains usable even when the optional filter cannot load.
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    if (_isLoading || (!reset && !_hasMore)) {
      return;
    }

    final page = reset ? 1 : _currentPage + 1;

    setState(() {
      _isLoading = true;
      if (reset) {
        _error = null;
      }
    });

    try {
      final result = await _api.getSessions(
        page: page,
        limit: 20,
        instrumentId: _selectedInstrumentId,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _sessions
            ..clear()
            ..addAll(result.items);
        } else {
          _sessions.addAll(result.items);
        }

        _currentPage = result.page;
        _hasMore = result.page < result.totalPages;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectInstrument(String? instrumentId) async {
    setState(() {
      _selectedInstrumentId = instrumentId;
      _currentPage = 0;
      _hasMore = true;
    });

    await _loadPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final showInitialLoader = _isLoading && _sessions.isEmpty && _error == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Practice history'),
        backgroundColor: const Color(0xFFF7F7F2),
      ),
      body: showInitialLoader
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _sessions.isEmpty
          ? _ErrorView(message: _error!, onRetry: () => _loadPage(reset: true))
          : RefreshIndicator(
              onRefresh: () => _loadPage(reset: true),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Filter by instrument',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _InstrumentFilters(
                    instruments: _instruments,
                    selectedInstrumentId: _selectedInstrumentId,
                    isDisabled: _isLoading,
                    onSelected: _selectInstrument,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    _InlineError(
                      message: _error!,
                      onRetry: () => _loadPage(reset: true),
                    ),
                  if (_sessions.isEmpty)
                    const _EmptyHistory()
                  else
                    ..._sessions.map(
                      (session) => _SessionTile(session: session),
                    ),
                  if (_isLoading && _sessions.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_isLoading && !_hasMore && _sessions.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No more sessions',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _InstrumentFilters extends StatelessWidget {
  const _InstrumentFilters({
    required this.instruments,
    required this.selectedInstrumentId,
    required this.isDisabled,
    required this.onSelected,
  });

  final List<PracticeHistoryInstrument> instruments;
  final String? selectedInstrumentId;
  final bool isDisabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedInstrumentId == null,
            onSelected: isDisabled
                ? null
                : (_) {
                    onSelected(null);
                  },
          ),
          const SizedBox(width: 8),
          ...instruments.map(
            (instrument) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(instrument.name),
                selected: selectedInstrumentId == instrument.id,
                onSelected: isDisabled
                    ? null
                    : (_) {
                        onSelected(instrument.id);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final PracticeHistorySession session;

  @override
  Widget build(BuildContext context) {
    final note = session.notes?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${session.durationMinutes}m',
            style: const TextStyle(
              color: Color(0xFF1F7A5A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          session.instrumentName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(session.startedAt)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        trailing: session.mood == null
            ? null
            : Tooltip(
                message: 'Mood: ${_moodLabel(session.mood!)}',
                child: Icon(_moodIcon(session.mood!)),
              ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
  }

  String _moodLabel(String mood) {
    switch (mood) {
      case 'great':
        return 'Great';
      case 'good':
        return 'Good';
      case 'okay':
        return 'Okay';
      case 'bad':
        return 'Bad';
      default:
        return mood;
    }
  }

  IconData _moodIcon(String mood) {
    switch (mood) {
      case 'great':
        return Icons.sentiment_very_satisfied_outlined;
      case 'good':
        return Icons.sentiment_satisfied_outlined;
      case 'okay':
        return Icons.sentiment_neutral_outlined;
      default:
        return Icons.sentiment_dissatisfied_outlined;
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 52,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 12),
          Text('No completed sessions yet'),
          SizedBox(height: 4),
          Text(
            'Finish a practice timer to see it here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Color(0xFFB42318)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: const Color(0xFFFEE4E2),
        leading: const Icon(Icons.error_outline, color: Color(0xFFB42318)),
        title: Text(message),
        trailing: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh),
          onPressed: onRetry,
        ),
      ),
    );
  }
}
