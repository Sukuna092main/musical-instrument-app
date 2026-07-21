import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_api.dart';

/// Admin Chords — CRUD, filters, toggle status.
class AdminChordsScreen extends StatefulWidget {
  const AdminChordsScreen({super.key});

  @override
  State<AdminChordsScreen> createState() => _AdminChordsScreenState();
}

class _AdminChordsScreenState extends State<AdminChordsScreen> {
  final AdminApi _api = AdminApi(ApiClient());
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  List<AdminChord> _items = [];
  AdminPagination? _pagination;
  bool _loading = true;
  String? _error;

  int _page = 1;
  String? _statusFilter;
  String? _difficultyFilter;
  bool? _isVipFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.listChords(
        query: AdminListQuery(
          page: _page,
          limit: 20,
          status: _statusFilter,
          difficulty: _difficultyFilter,
          isVip: _isVipFilter,
          search: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _pagination = result.pagination;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _onSearch() {
    _page = 1;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  // ── Toggle status ──

  Future<void> _toggleStatus(AdminChord item) async {
    final newStatus = item.status == 'active' ? 'hidden' : 'active';
    final label = newStatus == 'active' ? 'Show' : 'Hide';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label "${item.name}"?'),
        content: Text('Set chord status to $newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: newStatus == 'active'
                  ? AppColors.accent
                  : AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.updateChordStatus(item.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chord $newStatus ✓'),
          backgroundColor: AppColors.accent,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Create / Edit ──

  void _openForm({AdminChord? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChordFormSheet(
        api: _api,
        existing: existing,
        onSave: (body) async {
          Navigator.pop(ctx);
          if (existing != null) {
            await _update(existing.id, body);
          } else {
            await _create(body);
          }
        },
      ),
    );
  }

  Future<void> _create(Map<String, dynamic> body) async {
    try {
      await _api.createChord(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chord created ✓'),
          backgroundColor: AppColors.accent,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _update(String id, Map<String, dynamic> body) async {
    try {
      await _api.updateChord(id, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chord updated ✓'),
          backgroundColor: AppColors.accent,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Detail ──

  void _showDetail(AdminChord item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => _ChordDetailSheet(
          item: item,
          scrollController: scrollCtrl,
          dateFmt: _dateFmt,
          onEdit: () {
            Navigator.pop(ctx);
            _openForm(existing: item);
          },
          onToggleStatus: () {
            Navigator.pop(ctx);
            _toggleStatus(item);
          },
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        title: const Text('Chords'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search + filters
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search chords…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DropdownChip(
                        label: 'All status',
                        value: _statusFilter,
                        options: const {
                          null: 'All status',
                          'active': 'Active',
                          'hidden': 'Hidden',
                          'draft': 'Draft',
                        },
                        onSelected: (v) {
                          _statusFilter = v;
                          _page = 1;
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _DropdownChip(
                        label: 'All difficulties',
                        value: _difficultyFilter,
                        options: const {
                          null: 'All difficulties',
                          'beginner': 'Beginner',
                          'intermediate': 'Intermediate',
                          'advanced': 'Advanced',
                        },
                        onSelected: (v) {
                          _difficultyFilter = v;
                          _page = 1;
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _DropdownChip(
                        label: 'Free & VIP',
                        value: _isVipFilter == null
                            ? null
                            : _isVipFilter!
                            ? 'true'
                            : 'false',
                        options: const {
                          null: 'Free & VIP',
                          'false': 'Free only',
                          'true': 'VIP only',
                        },
                        onSelected: (v) {
                          _isVipFilter = v == null ? null : v == 'true';
                          _page = 1;
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'No chords found',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ChordTile(
                item: _items[i],
                dateFmt: _dateFmt,
                onTap: () => _showDetail(_items[i]),
                onEdit: () => _openForm(existing: _items[i]),
                onToggleStatus: () => _toggleStatus(_items[i]),
              ),
            ),
          ),
        ),
        if (_pagination != null && _pagination!.totalPages > 1)
          _PaginationBar(pagination: _pagination!, onPageChanged: _goToPage),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Chord tile
// ─────────────────────────────────────────────

class _ChordTile extends StatelessWidget {
  const _ChordTile({
    required this.item,
    required this.dateFmt,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminChord item;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isHidden = item.status == 'hidden';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Opacity(
          opacity: isHidden ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon / Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.symbol ?? item.name.substring(0, 1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badges
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isVip) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lockBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VIP',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Type + status
                      Row(
                        children: [
                          _DifficultyBadge(difficulty: item.difficulty),
                          const SizedBox(width: 6),
                          _StatusBadge(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item.instrumentName != null)
                        Text(
                          'Instrument: ${item.instrumentName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isHidden ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: isHidden
                                ? AppColors.accent
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(isHidden ? 'Show' : 'Hide'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────

class _ChordDetailSheet extends StatelessWidget {
  const _ChordDetailSheet({
    required this.item,
    required this.scrollController,
    required this.dateFmt,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminChord item;
  final ScrollController scrollController;
  final DateFormat dateFmt;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isHidden = item.status == 'hidden';

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Image / Diagram
        if (item.diagramUrl != null && item.diagramUrl!.isNotEmpty)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.diagramUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                item.symbol ?? item.name.substring(0, 1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Name + badges
        Center(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        if (item.symbol != null && item.symbol!.isNotEmpty)
          Center(
            child: Text(
              item.symbol!,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DifficultyBadge(difficulty: item.difficulty),
              const SizedBox(width: 6),
              _StatusBadge(status: item.status),
              if (item.isVip) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lockBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 12,
                        color: AppColors.goldText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        _DetailRow(label: 'Category', value: item.category),
        _DetailRow(
          label: 'Instrument',
          value: item.instrumentName ?? item.instrumentId ?? 'Any',
        ),
        if (item.description != null && item.description!.isNotEmpty)
          _DetailRow(label: 'Description', value: item.description!),
        _DetailRow(label: 'Sort Order', value: item.sortOrder.toString()),
        _DetailRow(
          label: 'Created At',
          value: dateFmt.format(item.createdAt.toLocal()),
        ),

        if (item.audioUrl != null && item.audioUrl!.isNotEmpty)
          _DetailRow(label: 'Audio URL', value: item.audioUrl!),

        const SizedBox(height: 32),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(
                  isHidden ? Icons.visibility : Icons.visibility_off,
                  color: isHidden ? AppColors.accent : AppColors.error,
                ),
                label: Text(
                  isHidden ? 'Show' : 'Hide',
                  style: TextStyle(
                    color: isHidden ? AppColors.accent : AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isHidden ? AppColors.accent : AppColors.error,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Create / Edit form sheet
// ─────────────────────────────────────────────

class _ChordFormSheet extends StatefulWidget {
  const _ChordFormSheet({
    required this.api,
    this.existing,
    required this.onSave,
  });

  final AdminApi api;
  final AdminChord? existing;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  State<_ChordFormSheet> createState() => _ChordFormSheetState();
}

class _ChordFormSheetState extends State<_ChordFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  String? _symbol;
  late String _category;
  String? _instrumentId;
  String? _description;
  String? _diagramUrl;
  String? _audioUrl;
  late String _difficulty;
  late bool _isVip;
  late int _sortOrder;
  late String _status;
  List<AdminInstrument> _instruments = [];
  bool _loadingInstruments = true;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _name = ex?.name ?? '';
    _symbol = ex?.symbol;
    _category = ex?.category ?? 'Major';
    _instrumentId = ex?.instrumentId;
    _description = ex?.description;
    _diagramUrl = ex?.diagramUrl;
    _audioUrl = ex?.audioUrl;
    _difficulty = ex?.difficulty ?? 'beginner';
    _isVip = ex?.isVip ?? false;
    _sortOrder = ex?.sortOrder ?? 0;
    _status = ex?.status ?? 'active';
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    try {
      final res = await widget.api.listInstruments(
        query: const AdminListQuery(limit: 100),
      );
      if (!mounted) return;
      setState(() {
        _instruments = res.items;
        _loadingInstruments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInstruments = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.onSave({
      'name': _name.trim(),
      if (_symbol != null && _symbol!.trim().isNotEmpty)
        'symbol': _symbol!.trim(),
      'category': _category.trim(),
      if (_instrumentId != null && _instrumentId!.trim().isNotEmpty)
        'instrumentId': _instrumentId!.trim(),
      if (_description != null && _description!.trim().isNotEmpty)
        'description': _description!.trim(),
      if (_diagramUrl != null && _diagramUrl!.trim().isNotEmpty)
        'diagramUrl': _diagramUrl!.trim(),
      if (_audioUrl != null && _audioUrl!.trim().isNotEmpty)
        'audioUrl': _audioUrl!.trim(),
      'difficulty': _difficulty,
      'isVip': _isVip,
      'sortOrder': _sortOrder,
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'New Chord' : 'Edit Chord',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 16),

              // Symbol
              TextFormField(
                initialValue: _symbol,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'e.g. C, Cmaj7, Am',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                ),
                onSaved: (v) => _symbol = v,
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'e.g. Major, Minor, Seventh',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _category = v ?? '',
              ),
              const SizedBox(height: 16),

              // Instrument Dropdown
              _loadingInstruments
                  ? const Center(child: LinearProgressIndicator())
                  : DropdownButtonFormField<String?>(
                      initialValue: _instrumentId,
                      decoration: const InputDecoration(
                        labelText: 'Instrument (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.piano),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General / All Instruments'),
                        ),
                        ..._instruments.map(
                          (inst) => DropdownMenuItem<String?>(
                            value: inst.id,
                            child: Text('${inst.name} (${inst.type})'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _instrumentId = v),
                      onSaved: (v) => _instrumentId = v,
                    ),
              const SizedBox(height: 16),

              // Difficulty & Status
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Beginner'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Intermediate'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Advanced'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _difficulty = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'hidden',
                          child: Text('Hidden'),
                        ),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // VIP switch + Sort order
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('VIP Only'),
                      contentPadding: EdgeInsets.zero,
                      value: _isVip,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _isVip = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _sortOrder.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Sort Order',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _sortOrder = int.tryParse(v ?? '0') ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 16),

              // Diagram URL
              TextFormField(
                initialValue: _diagramUrl,
                decoration: const InputDecoration(
                  labelText: 'Diagram URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
                onSaved: (v) => _diagramUrl = v,
              ),
              const SizedBox(height: 16),

              // Audio URL
              TextFormField(
                initialValue: _audioUrl,
                decoration: const InputDecoration(
                  labelText: 'Audio URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.audiotrack),
                ),
                onSaved: (v) => _audioUrl = v,
              ),
              const SizedBox(height: 24),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (difficulty) {
      case 'beginner':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Beginner';
        break;
      case 'intermediate':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'Intermediate';
        break;
      case 'advanced':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Advanced';
        break;
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerLow;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
        label = difficulty;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'active':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Active';
        break;
      case 'hidden':
        bg = Theme.of(context).colorScheme.surfaceContainerLow;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'Hidden';
        break;
      case 'draft':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Draft';
        break;
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerLow;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final Map<String?, String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => options.entries
          .map(
            (e) => PopupMenuItem<String?>(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  fontWeight: e.key == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value == null ? Theme.of(context).colorScheme.surfaceContainerLow : AppColors.accentSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value == null ? Theme.of(context).colorScheme.outlineVariant : AppColors.accent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              options[value] ?? label,
              style: TextStyle(
                fontSize: 13,
                color: value == null ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.accent,
                fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: value == null ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.pagination, required this.onPageChanged});

  final AdminPagination pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${pagination.page} of ${pagination.totalPages}',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pagination.page > 1
                    ? () => onPageChanged(pagination.page - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pagination.page < pagination.totalPages
                    ? () => onPageChanged(pagination.page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
