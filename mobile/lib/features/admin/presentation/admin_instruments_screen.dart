import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_api.dart';

/// Admin Instruments — CRUD, VIP flag, tags, toggle status.
class AdminInstrumentsScreen extends StatefulWidget {
  const AdminInstrumentsScreen({super.key});

  @override
  State<AdminInstrumentsScreen> createState() => _AdminInstrumentsScreenState();
}

class _AdminInstrumentsScreenState extends State<AdminInstrumentsScreen> {
  final AdminApi _api = AdminApi(ApiClient());
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  List<AdminInstrument> _items = [];
  AdminPagination? _pagination;
  bool _loading = true;
  String? _error;

  int _page = 1;
  String? _statusFilter;
  String? _typeFilter;
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
      final result = await _api.listInstruments(
        query: AdminListQuery(
          page: _page,
          limit: 20,
          status: _statusFilter,
          type: _typeFilter,
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

  Future<void> _toggleStatus(AdminInstrument item) async {
    final newStatus = item.status == 'active' ? 'hidden' : 'active';
    final label = newStatus == 'active' ? 'Show' : 'Hide';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label "${item.name}"?'),
        content: Text('Set instrument status to $newStatus?'),
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
      await _api.updateInstrumentStatus(item.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Instrument $newStatus ✓'),
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

  void _openForm({AdminInstrument? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InstrumentFormSheet(
        existing: existing,
        onSave: (instrument) async {
          Navigator.pop(ctx);
          if (existing != null) {
            await _update(existing.id, instrument);
          } else {
            await _create(instrument);
          }
        },
      ),
    );
  }

  Future<void> _create(AdminInstrument instrument) async {
    try {
      await _api.createInstrument(instrument);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrument created ✓'),
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

  Future<void> _update(String id, AdminInstrument instrument) async {
    try {
      await _api.updateInstrument(id, instrument);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrument updated ✓'),
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

  void _showDetail(AdminInstrument item) {
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
        builder: (_, scrollCtrl) => _InstrumentDetailSheet(
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
        title: const Text('Instruments'),
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
                    hintText: 'Search instruments…',
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
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                        },
                        onSelected: (v) {
                          _statusFilter = v;
                          _page = 1;
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _DropdownChip(
                        label: 'All types',
                        value: _typeFilter,
                        options: const {
                          null: 'All types',
                          'guitar': 'Guitar',
                          'piano': 'Piano',
                          'drum': 'Drum',
                          'violin': 'Violin',
                          'saxophone': 'Saxophone',
                          'flute': 'Flute',
                          'other': 'Other',
                        },
                        onSelected: (v) {
                          _typeFilter = v;
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
            Icon(Icons.piano_off, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No instruments found',
              style: TextStyle(color: Colors.black54),
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
              itemBuilder: (_, i) => _InstrumentTile(
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
// Instrument tile
// ─────────────────────────────────────────────

class _InstrumentTile extends StatelessWidget {
  const _InstrumentTile({
    required this.item,
    required this.dateFmt,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminInstrument item;
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
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ImagePlaceholder(name: item.name),
                        )
                      : _ImagePlaceholder(name: item.name),
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
                      // Type + status
                      Row(
                        children: [
                          _TypeBadge(type: item.type),
                          const SizedBox(width: 6),
                          _StatusBadge(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Tags
                      if (item.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: item.tags
                              .take(4)
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.piano,
          color: AppColors.accent.withValues(alpha: 0.4),
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────

class _InstrumentDetailSheet extends StatelessWidget {
  const _InstrumentDetailSheet({
    required this.item,
    required this.scrollController,
    required this.dateFmt,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final AdminInstrument item;
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

        // Image
        if (item.imageUrl.isNotEmpty)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
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
            child: const Center(
              child: Icon(Icons.piano, size: 48, color: AppColors.accent),
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
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypeBadge(type: item.type),
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

        // Tags
        if (item.tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Details
        _DetailRow(label: 'Type', value: item.type),
        _DetailRow(label: 'VIP', value: item.isVip ? 'Yes' : 'No'),
        _DetailRow(label: 'Audio', value: item.audioSampleUrl ?? 'None'),
        _DetailRow(label: 'Created', value: dateFmt.format(item.createdAt)),
        _DetailRow(label: 'ID', value: item.id),
        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isHidden
                        ? AppColors.accent.withValues(alpha: 0.6)
                        : AppColors.error.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isHidden ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: isHidden ? AppColors.accent : AppColors.error,
                ),
                label: Text(
                  isHidden ? 'Show' : 'Hide',
                  style: TextStyle(
                    color: isHidden ? AppColors.accent : AppColors.error,
                  ),
                ),
                onPressed: onToggleStatus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Create / Edit form
// ─────────────────────────────────────────────

class _InstrumentFormSheet extends StatefulWidget {
  const _InstrumentFormSheet({this.existing, required this.onSave});

  final AdminInstrument? existing;
  final Future<void> Function(AdminInstrument instrument) onSave;

  @override
  State<_InstrumentFormSheet> createState() => _InstrumentFormSheetState();
}

class _InstrumentFormSheetState extends State<_InstrumentFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imgCtrl;
  late final TextEditingController _audioCtrl;
  late final TextEditingController _tagsCtrl;
  late String _type;
  late String _status;
  late bool _isVip;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  static const _types = [
    'guitar',
    'piano',
    'drum',
    'violin',
    'saxophone',
    'flute',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _imgCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _audioCtrl = TextEditingController(text: e?.audioSampleUrl ?? '');
    _tagsCtrl = TextEditingController(text: e?.tags.join(', ') ?? '');
    _type = e?.type ?? 'guitar';
    _status = e?.status ?? 'active';
    _isVip = e?.isVip ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _audioCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final instrument = AdminInstrument(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      imageUrl: _imgCtrl.text.trim(),
      audioSampleUrl: _audioCtrl.text.trim().isEmpty
          ? null
          : _audioCtrl.text.trim(),
      isVip: _isVip,
      tags: tags,
      status: _status,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(instrument);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
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
              // Title
              Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit : Icons.add_circle_outline,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit ? 'Edit Instrument' : 'New Instrument',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              _FieldLabel(label: 'Name *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecor('e.g. Acoustic Guitar'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _FieldLabel(label: 'Description *'),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDecor('Instrument description'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Image URL
              _FieldLabel(label: 'Image URL *'),
              TextFormField(
                controller: _imgCtrl,
                decoration: _inputDecor('https://...'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Type
              _FieldLabel(label: 'Type *'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: _inputDecor(null),
                items: _types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),

              // Status
              _FieldLabel(label: 'Status'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _inputDecor(null),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 16),

              // VIP switch
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 20,
                      color: AppColors.goldText,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'VIP instrument',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: _isVip,
                      activeThumbColor: AppColors.goldText,
                      onChanged: (v) => setState(() => _isVip = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audio sample URL
              _FieldLabel(label: 'Audio sample URL (optional)'),
              TextFormField(
                controller: _audioCtrl,
                decoration: _inputDecor('https://…'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Tags
              _FieldLabel(label: 'Tags (comma-separated)'),
              TextFormField(
                controller: _tagsCtrl,
                decoration: _inputDecor('beginner, popular, classic'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save changes' : 'Create instrument',
                          style: const TextStyle(fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'string':
        icon = Icons.music_note;
        break;
      case 'wind':
        icon = Icons.air;
        break;
      case 'percussion':
        icon = Icons.sports_handball;
        break;
      case 'keyboard':
        icon = Icons.piano;
        break;
      case 'electronic':
        icon = Icons.electric_bolt;
        break;
      default:
        icon = Icons.category;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentSurface : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.visibility : Icons.visibility_off,
            size: 11,
            color: isActive ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
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
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      itemBuilder: (_) => options.entries.map((e) {
        return PopupMenuItem<String?>(
          value: e.key,
          child: Row(
            children: [
              if (e.key == value)
                const Icon(Icons.check, size: 16, color: AppColors.accent)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(e.value),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value != null ? AppColors.accentSurface : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null
                ? AppColors.accent.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null ? options[value]! : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value != null ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: value != null ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${pagination.page} of ${pagination.totalPages}'
            '  ·  ${pagination.total} instruments',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: pagination.page > 1
                    ? () => onPageChanged(pagination.page - 1)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: pagination.page < pagination.totalPages
                    ? () => onPageChanged(pagination.page + 1)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
