import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/practice_api.dart';
import '../data/practice_timer_api.dart';
import '../../instruments/presentation/instruments_screen.dart';

class PracticeTimerScreen extends StatefulWidget {
  const PracticeTimerScreen({super.key});

  @override
  State<PracticeTimerScreen> createState() => _PracticeTimerScreenState();
}

class _PracticeTimerScreenState extends State<PracticeTimerScreen> {
  final PracticeTimerApi _api = PracticeTimerApi(ApiClient());
  final TextEditingController _notesController = TextEditingController();

  List<UserPracticeInstrument> _instruments = [];
  UserPracticeInstrument? _selectedInstrument;
  ActivePracticeSession? _activeSession;
  Timer? _ticker;

  String? _mood;
  String? _error;
  bool _isLoading = true;
  bool _isStarting = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeSession = await _api.getActiveSession();
      final instruments = activeSession == null
          ? await _api.getUserInstruments()
          : <UserPracticeInstrument>[];

      if (!mounted) return;

      UserPracticeInstrument? selected;
      if (instruments.isNotEmpty) {
        selected = instruments.firstWhere(
          (item) => item.instrumentId == _selectedInstrument?.instrumentId,
          orElse: () => instruments.first,
        );
      }

      setState(() {
        _activeSession = activeSession;
        _instruments = instruments;
        _selectedInstrument = selected;
        _isLoading = false;
      });

      _startTicker();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _openInstruments() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstrumentsScreen()));

    if (mounted) {
      await _load();
    }
  }

  void _startTicker() {
    _ticker?.cancel();

    if (_activeSession == null) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _startSession() async {
    final instrument = _selectedInstrument;

    if (instrument == null) {
      return;
    }

    setState(() {
      _isStarting = true;
      _error = null;
    });

    try {
      final session = await _api.startSession(instrument.instrumentId);

      if (!mounted) return;

      setState(() {
        _activeSession = session;
        _isStarting = false;
      });

      _startTicker();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
        _isStarting = false;
      });
    }
  }

  Future<void> _endSession() async {
    final session = _activeSession;

    if (session == null) {
      return;
    }

    setState(() {
      _isEnding = true;
      _error = null;
    });

    try {
      await _api.endSession(
        sessionId: session.id,
        notes: _notesController.text,
        mood: _mood,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
        _isEnding = false;
      });
    }
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _formatElapsed(DateTime startedAt) {
    final elapsed = DateTime.now().difference(startedAt);
    final totalSeconds = elapsed.isNegative ? 0 : elapsed.inSeconds;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Practice timer'),
        backgroundColor: const Color(0xFFF7F7F2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _load)
          : _activeSession == null
          ? _StartSessionView(
              instruments: _instruments,
              selectedInstrument: _selectedInstrument,
              isStarting: _isStarting,
              onInstrumentChanged: (instrument) {
                setState(() => _selectedInstrument = instrument);
              },
              onStart: _startSession,
              onAddInstrument: _openInstruments,
            )
          : _ActiveSessionView(
              session: _activeSession!,
              elapsed: _formatElapsed(_activeSession!.startedAt),
              notesController: _notesController,
              mood: _mood,
              isEnding: _isEnding,
              onMoodChanged: (mood) {
                setState(() => _mood = mood);
              },
              onEnd: _endSession,
            ),
    );
  }
}

class _StartSessionView extends StatelessWidget {
  const _StartSessionView({
    required this.instruments,
    required this.selectedInstrument,
    required this.isStarting,
    required this.onInstrumentChanged,
    required this.onStart,
    required this.onAddInstrument,
  });

  final List<UserPracticeInstrument> instruments;
  final UserPracticeInstrument? selectedInstrument;
  final bool isStarting;
  final ValueChanged<UserPracticeInstrument?> onInstrumentChanged;
  final VoidCallback onStart;
  final VoidCallback onAddInstrument;

  @override
  Widget build(BuildContext context) {
    final hasInstruments = instruments.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.timer_outlined, size: 54, color: Color(0xFF1F7A5A)),
        const SizedBox(height: 16),
        Text(
          'Ready to practice?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose an instrument and start tracking your session.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        DropdownButtonFormField<UserPracticeInstrument>(
          value: selectedInstrument,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Instrument',
            border: OutlineInputBorder(),
          ),
          items: instruments
              .map(
                (instrument) => DropdownMenuItem(
                  value: instrument,
                  child: Text(instrument.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: isStarting ? null : onInstrumentChanged,
        ),
        if (!hasInstruments) ...[
          const SizedBox(height: 12),
          const Text(
            'You have not added an instrument to your profile yet.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddInstrument,
            icon: const Icon(Icons.add),
            label: const Text('Add instrument'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: hasInstruments && !isStarting ? onStart : null,
          icon: isStarting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(isStarting ? 'Starting...' : 'Start practice'),
        ),
      ],
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView({
    required this.session,
    required this.elapsed,
    required this.notesController,
    required this.mood,
    required this.isEnding,
    required this.onMoodChanged,
    required this.onEnd,
  });

  final ActivePracticeSession session;
  final String elapsed;
  final TextEditingController notesController;
  final String? mood;
  final bool isEnding;
  final ValueChanged<String?> onMoodChanged;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF163B32),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 34),
              const SizedBox(height: 12),
              Text(
                session.instrumentName,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                elapsed,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Session in progress',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: notesController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Practice notes',
            hintText: 'What did you work on today?',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'How did it feel?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: 'great', label: Text('Great')),
            ButtonSegment(value: 'good', label: Text('Good')),
            ButtonSegment(value: 'okay', label: Text('Okay')),
            ButtonSegment(value: 'bad', label: Text('Bad')),
          ],
          selected: mood == null ? <String>{} : {mood!},
          onSelectionChanged: (selection) {
            onMoodChanged(selection.isEmpty ? null : selection.first);
          },
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
          ),
          onPressed: isEnding ? null : onEnd,
          icon: isEnding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.stop),
          label: Text(isEnding ? 'Saving...' : 'End and save session'),
        ),
      ],
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
