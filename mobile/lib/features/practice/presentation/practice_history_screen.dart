import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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
    final l10n = context.l10n;
    final showInitialLoader = _isLoading && _sessions.isEmpty && _error == null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.practiceHistory)),
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
                    l10n.filterByInstrument,
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
                    _EmptyHistory()
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        l10n.noMoreSessions,
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
            label: Text(context.l10n.all),
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
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${session.durationMinutes}m',
            style: const TextStyle(
              color: AppColors.accent,
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
                message: l10n.moodGreat, // fallback label, refined below
                child: Icon(_moodIcon(session.mood!)),
              ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
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
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 52,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 12),
          Text(l10n.noCompletedSessionsYet),
          const SizedBox(height: 4),
          Text(
            l10n.finishPracticeToSee,
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
            const Icon(Icons.error_outline, size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
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
        tileColor: AppColors.errorSurface,
        leading: const Icon(Icons.error_outline, color: AppColors.error),
        title: Text(message),
        trailing: IconButton(
          tooltip: context.l10n.retry,
          icon: const Icon(Icons.refresh),
          onPressed: onRetry,
        ),
      ),
    );
  }
}
