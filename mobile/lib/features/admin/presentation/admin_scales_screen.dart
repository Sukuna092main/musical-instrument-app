import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_api.dart';

/// Admin Scales — CRUD, VIP flag, filters, toggle status.
class AdminScalesScreen extends StatefulWidget {
  const AdminScalesScreen({super.key});

  @override
  State<AdminScalesScreen> createState() => _AdminScalesScreenState();
}

class _AdminScalesScreenState extends State<AdminScalesScreen> {
  final AdminApi _api = AdminApi(ApiClient());
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  List<AdminScale> _items = [];
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
      final result = await _api.listScales(
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

  Future<void> _toggleStatus(AdminScale item) async {
    final newStatus = item.status == 'active' ? 'hidden' : 'active';
    final label = newStatus == 'active' ? 'Activate' : 'Hide';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label "${item.name}"?'),
        content: Text('Set scale status to $newStatus?'),
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
      await _api.updateScaleStatus(item.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scale status updated to $newStatus ✓'),
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

  void _openForm({AdminScale? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScaleFormSheet(
        api: _api,
        existing: existing,
        onSave: (data) async {
          Navigator.pop(ctx);
          if (existing != null) {
            await _update(existing.id, data);
          } else {
            await _create(data);
          }
        },
      ),
    );
  }

  Future<void> _create(Map<String, dynamic> data) async {
    try {
      await _api.createScale(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scale created ✓'),
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

  Future<void> _update(String id, Map<String, dynamic> data) async {
    try {
      await _api.updateScale(id, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scale updated ✓'),
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

  void _showDetail(AdminScale item) {
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
        builder: (_, scrollCtrl) => _ScaleDetailSheet(
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
        title: const Text('Scales'),
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
                    hintText: 'Search by name, key, or type...',
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
            Icon(Icons.queue_music, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'No scales found',
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
              itemBuilder: (_, i) => _ScaleTile(
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
// Scale tile
// ─────────────────────────────────────────────

class _ScaleTile extends StatelessWidget {
  const _ScaleTile({
    required this.item,
    required this.dateFmt,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminScale item;
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
                      // Key + Type
                      Text(
                        'Key: ${item.key ?? '-'} • Type: ${item.scaleType}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Instrument
                      if (item.instrumentName != null)
                        Text(
                          'Instrument: ${item.instrumentName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Difficulty + status
                      Row(
                        children: [
                          _Badge(
                            text: item.difficulty.toUpperCase(),
                            color: _difficultyColor(item.difficulty),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(status: item.status),
                        ],
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

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────

class _ScaleDetailSheet extends StatelessWidget {
  const _ScaleDetailSheet({
    required this.item,
    required this.scrollController,
    required this.dateFmt,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminScale item;
  final ScrollController scrollController;
  final DateFormat dateFmt;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
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

        // Name + badges
        Center(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Badge(
                text: item.difficulty.toUpperCase(),
                color: _difficultyColor(item.difficulty),
              ),
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

        // Info Grid
        _InfoRow(label: 'ID', value: item.id),
        _InfoRow(label: 'Key', value: item.key ?? '-'),
        _InfoRow(label: 'Type', value: item.scaleType),
        _InfoRow(
          label: 'Instrument',
          value: item.instrumentName ?? item.instrumentId ?? 'Any',
        ),
        _InfoRow(label: 'Sort Order', value: item.sortOrder.toString()),
        _InfoRow(label: 'Created', value: dateFmt.format(item.createdAt)),

        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(item.description!, style: const TextStyle(fontSize: 14)),
        ],

        if (item.diagramUrl != null && item.diagramUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Diagram URL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          SelectableText(
            item.diagramUrl!,
            style: const TextStyle(fontSize: 14, color: AppColors.accent),
          ),
        ],

        if (item.audioUrl != null && item.audioUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Audio URL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          SelectableText(
            item.audioUrl!,
            style: const TextStyle(fontSize: 14, color: AppColors.accent),
          ),
        ],

        const SizedBox(height: 32),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(
                  item.status == 'active'
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 18,
                ),
                label: Text(item.status == 'active' ? 'Hide' : 'Activate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: item.status == 'active'
                      ? AppColors.error
                      : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Create / Edit Form Sheet
// ─────────────────────────────────────────────

class _ScaleFormSheet extends StatefulWidget {
  const _ScaleFormSheet({
    required this.api,
    this.existing,
    required this.onSave,
  });

  final AdminApi api;
  final AdminScale? existing;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<_ScaleFormSheet> createState() => _ScaleFormSheetState();
}

class _ScaleFormSheetState extends State<_ScaleFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _key;
  late String _scaleType;
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
    final e = widget.existing;
    _name = e?.name ?? '';
    _key = e?.key ?? '';
    _scaleType = e?.scaleType ?? '';
    _instrumentId = e?.instrumentId;
    _description = e?.description;
    _diagramUrl = e?.diagramUrl;
    _audioUrl = e?.audioUrl;
    _difficulty = e?.difficulty ?? 'beginner';
    _isVip = e?.isVip ?? false;
    _sortOrder = e?.sortOrder ?? 0;
    _status = e?.status ?? 'active';
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

    final data = <String, dynamic>{
      'name': _name.trim(),
      'key': _key.trim().isEmpty ? null : _key.trim(),
      'scaleType': _scaleType.trim(),
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
    };
    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Create Scale' : 'Edit Scale',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _key,
                      decoration: const InputDecoration(
                        labelText: 'Key (e.g. C, G#)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSaved: (v) => _key = v ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _scaleType,
                      decoration: const InputDecoration(
                        labelText: 'Type * (major, minor...)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onSaved: (v) => _scaleType = v ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Instrument Dropdown
              _loadingInstruments
                  ? const Center(child: LinearProgressIndicator())
                  : DropdownButtonFormField<String?>(
                      initialValue: _instrumentId,
                      decoration: const InputDecoration(
                        labelText: 'Instrument (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
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
              const SizedBox(height: 12),

              // Description
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 12),

              // Diagram & Audio URL
              TextFormField(
                initialValue: _diagramUrl,
                decoration: const InputDecoration(
                  labelText: 'Diagram URL (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSaved: (v) => _diagramUrl = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _audioUrl,
                decoration: const InputDecoration(
                  labelText: 'Audio URL (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSaved: (v) => _audioUrl = v,
              ),
              const SizedBox(height: 16),

              // Dropdowns: difficulty & status
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                        isDense: true,
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
                      onSaved: (v) => _difficulty = v ?? 'beginner',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
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
                      onSaved: (v) => _status = v ?? 'active',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _sortOrder.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Sort Order',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _sortOrder = int.tryParse(v ?? '') ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('VIP Only'),
                      contentPadding: EdgeInsets.zero,
                      value: _isVip,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _isVip = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: const Text('Save Scale'),
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
    final display = options[value] ?? label;
    final isActive = value != null;

    return PopupMenuButton<String?>(
      initialValue: value,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => options.entries
          .map(
            (e) => PopupMenuItem<String?>(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  fontWeight: e.key == value ? FontWeight.bold : null,
                  color: e.key == value ? AppColors.accent : null,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentSurface : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.accent : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
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
    Color text;
    String label = status.toUpperCase();

    switch (status) {
      case 'active':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        break;
      case 'hidden':
        bg = Theme.of(context).colorScheme.surfaceContainerLow;
        text = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      case 'draft':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        break;
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerLow;
        text = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${pagination.total}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pagination.page > 1
                    ? () => onPageChanged(pagination.page - 1)
                    : null,
              ),
              Text(
                '${pagination.page} / ${pagination.totalPages}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
