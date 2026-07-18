import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/instruments_api.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  late final InstrumentsApi _api;
  List<UserInstrument> _mine = [];
  bool _isLoading = true;
  String? _loadError;
  String? _busyInstrumentId;

  @override
  void initState() {
    super.initState();
    _api = InstrumentsApi(ApiClient());
    _loadMine();
  }

  Future<void> _loadMine() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final mine = await _api.getMine();
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Add ──
  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddInstrumentSheet(
        api: _api,
        existingInstrumentIds: _mine.map((e) => e.instrumentId).toSet(),
      ),
    );

    if (added == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Instrument added')));
      await _loadMine();
    }
  }

  // ── Edit ──
  Future<void> _openEditSheet(UserInstrument instrument) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _EditInstrumentSheet(api: _api, instrument: instrument),
    );

    if (changed == true && mounted) {
      await _loadMine();
    }
  }

  // ── Remove ──
  Future<void> _confirmRemove(UserInstrument instrument) async {
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove instrument'),
        content: Text('Remove ${instrument.name} from your instruments?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyInstrumentId = instrument.instrumentId);

    try {
      await _api.remove(instrument.instrumentId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${instrument.name} removed')));
      await _loadMine();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyInstrumentId = null);
    }
  }

  // ── Quick set primary ──
  Future<void> _setPrimary(UserInstrument instrument) async {
    if (instrument.isPrimary) return;

    setState(() => _busyInstrumentId = instrument.instrumentId);

    try {
      await _api.update(instrument.instrumentId, isPrimary: true);
      if (!mounted) return;
      await _loadMine();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyInstrumentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My instruments'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add instrument',
            icon: const Icon(Icons.add),
            onPressed: _isLoading ? null : _openAddSheet,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadMine,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            'Could not load instruments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_loadError!),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadMine, child: const Text('Try again')),
        ],
      );
    }

    if (_mine.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _loadMine,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mine.length,
        itemBuilder: (context, index) {
          final instrument = _mine[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InstrumentCard(
              instrument: instrument,
              isBusy: _busyInstrumentId == instrument.instrumentId,
              onTap: () => _openEditSheet(instrument),
              onSetPrimary: instrument.isPrimary
                  ? null
                  : () => _setPrimary(instrument),
              onEdit: () => _openEditSheet(instrument),
              onRemove: () => _confirmRemove(instrument),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_outlined,
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No instruments yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Add an instrument to start tracking your practice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add),
              label: const Text('Browse instruments'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instrument card ──

enum _InstrumentAction { setPrimary, edit, remove }

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.instrument,
    required this.isBusy,
    required this.onTap,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onRemove,
  });

  final UserInstrument instrument;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onSetPrimary;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _InstrumentAvatar(imageUrl: instrument.imageUrl),
        title: Row(
          children: [
            Expanded(
              child: Text(
                instrument.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (instrument.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF163B32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                    SizedBox(width: 4),
                    Text(
                      'Primary',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${_capitalize(instrument.type)} · ${_capitalize(instrument.skillLevel)}',
        ),
        trailing: isBusy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<_InstrumentAction>(
                tooltip: 'Options',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _InstrumentAction.setPrimary:
                      onSetPrimary?.call();
                    case _InstrumentAction.edit:
                      onEdit();
                    case _InstrumentAction.remove:
                      onRemove();
                  }
                },
                itemBuilder: (context) => [
                  if (onSetPrimary != null)
                    const PopupMenuItem(
                      value: _InstrumentAction.setPrimary,
                      child: Row(
                        children: [
                          Icon(Icons.star_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Set as primary'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: _InstrumentAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 20),
                        SizedBox(width: 12),
                        Text('Edit skill level'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _InstrumentAction.remove,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Remove',
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: isBusy ? null : onTap,
      ),
    );
  }
}

// ── Avatar (dùng chung cho card + sheets) ──

class _InstrumentAvatar extends StatelessWidget {
  const _InstrumentAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url != null && url.trim().isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.primaryContainer,
      child: Icon(Icons.music_note, color: scheme.onPrimaryContainer),
    );
  }
}

// ── Add sheet ──

class _AddInstrumentSheet extends StatefulWidget {
  const _AddInstrumentSheet({
    required this.api,
    required this.existingInstrumentIds,
  });

  final InstrumentsApi api;
  final Set<String> existingInstrumentIds;

  @override
  State<_AddInstrumentSheet> createState() => _AddInstrumentSheetState();
}

class _AddInstrumentSheetState extends State<_AddInstrumentSheet> {
  late Future<List<InstrumentOption>> _future;
  final Map<String, String> _selectedSkill = {}; // instrumentId -> skill
  String? _addingId;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAvailable();
  }

  Future<void> _add(InstrumentOption option) async {
    setState(() => _addingId = option.id);

    try {
      await widget.api.add(
        option.id,
        skillLevel: _selectedSkill[option.id] ?? 'beginner',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Browse instruments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick an instrument to add to your practice.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<InstrumentOption>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _future = widget.api.getAvailable();
                    });
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final all = snapshot.data ?? [];
        final available = all
            .where((o) => !widget.existingInstrumentIds.contains(o.id))
            .toList();

        if (available.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'You have added all available instruments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: available.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final option = available[index];
            final isAdding = _addingId == option.id;
            final skill = _selectedSkill[option.id] ?? 'beginner';

            return _AvailableInstrumentTile(
              option: option,
              selectedSkill: skill,
              isAdding: isAdding,
              onSkillChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSkill[option.id] = value);
                }
              },
              onAdd: isAdding ? null : () => _add(option),
            );
          },
        );
      },
    );
  }
}

class _AvailableInstrumentTile extends StatelessWidget {
  const _AvailableInstrumentTile({
    required this.option,
    required this.selectedSkill,
    required this.isAdding,
    required this.onSkillChanged,
    required this.onAdd,
  });

  final InstrumentOption option;
  final String selectedSkill;
  final bool isAdding;
  final ValueChanged<String?> onSkillChanged;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _InstrumentAvatar(imageUrl: option.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _capitalize(option.type),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedSkill,
            underline: const SizedBox(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
              DropdownMenuItem(
                value: 'intermediate',
                child: Text('Intermediate'),
              ),
              DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
            ],
            onChanged: onSkillChanged,
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: isAdding
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Edit sheet ──

class _EditInstrumentSheet extends StatefulWidget {
  const _EditInstrumentSheet({required this.api, required this.instrument});

  final InstrumentsApi api;
  final UserInstrument instrument;

  @override
  State<_EditInstrumentSheet> createState() => _EditInstrumentSheetState();
}

class _EditInstrumentSheetState extends State<_EditInstrumentSheet> {
  late String _skill;
  late bool _isPrimary;
  bool _isSaving = false;

  static const _skills = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _skill = widget.instrument.skillLevel;
    _isPrimary = widget.instrument.isPrimary;
  }

  bool get _changed =>
      _skill != widget.instrument.skillLevel ||
      _isPrimary != widget.instrument.isPrimary;

  Future<void> _save() async {
    if (!_changed) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.api.update(
        widget.instrument.instrumentId,
        skillLevel: _skill,
        isPrimary: _isPrimary,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              _InstrumentAvatar(imageUrl: widget.instrument.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.instrument.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Skill level',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: _skills
                .map(
                  (s) => ButtonSegment(value: s, label: Text(_capitalize(s))),
                )
                .toList(),
            selected: {_skill},
            onSelectionChanged: (selection) {
              setState(() => _skill = selection.first);
            },
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as primary'),
            subtitle: const Text(
              'Your main instrument. Only one can be primary.',
            ),
            value: _isPrimary,
            activeTrackColor: scheme.primary,
            onChanged: (value) => setState(() => _isPrimary = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
