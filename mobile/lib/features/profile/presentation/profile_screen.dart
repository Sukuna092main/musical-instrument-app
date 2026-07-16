import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_api.dart';
import '../data/profile_api.dart';
import '../../vip/presentation/vip_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final ProfileApi _profileApi;

  late AuthUser _user;
  String? _avatarUrl;
  Uint8List? _localAvatarBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi(ApiClient());
    _user = widget.user;
    _avatarUrl = widget.user.avatarUrl;
  }

  Future<void> _chooseAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null || _isUploading) {
      return;
    }

    final mimeType = image.mimeType ?? _mimeTypeFromPath(image.path);

    if (mimeType == null) {
      _showMessage('Only JPG, PNG, and WEBP images are supported.');
      return;
    }

    final bytes = await image.readAsBytes();

    setState(() {
      _localAvatarBytes = bytes;
      _isUploading = true;
    });

    try {
      final avatarUrl = await _profileApi.uploadAvatar(
        bytes: bytes,
        filename: image.name,
        mimeType: mimeType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = avatarUrl;
        _localAvatarBytes = null;
        _user = _copyWith(avatarUrl: avatarUrl);
      });

      _showMessage('Profile photo updated.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _localAvatarBytes = null;
      });

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _openEditName() async {
    final updated = await showModalBottomSheet<AuthUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditFieldSheet(
        title: 'Edit full name',
        label: 'Full name',
        initialValue: _user.fullName,
        maxLines: 1,
        maxLength: 100,
        onSave: (value) => _profileApi.updateProfile(fullName: value),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
      _showMessage('Name updated.');
    }
  }

  Future<void> _openEditPhone() async {
    final updated = await showModalBottomSheet<AuthUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditFieldSheet(
        title: 'Edit phone',
        label: 'Phone number',
        initialValue: _user.phone ?? '',
        maxLines: 1,
        maxLength: 30,
        keyboardType: TextInputType.phone,
        onSave: (value) => _profileApi.updateProfile(phone: value),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
      _showMessage('Phone updated.');
    }
  }

  AuthUser _copyWith({String? fullName, String? phone, String? avatarUrl}) {
    return AuthUser(
      id: _user.id,
      fullName: fullName ?? _user.fullName,
      email: _user.email,
      avatarUrl: avatarUrl ?? _user.avatarUrl,
      phone: phone ?? _user.phone,
      role: _user.role,
      status: _user.status,
    );
  }

  String? _mimeTypeFromPath(String path) {
    final value = path.toLowerCase();

    if (value.endsWith('.jpg') || value.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (value.endsWith('.png')) {
      return 'image/png';
    }

    if (value.endsWith('.webp')) {
      return 'image/webp';
    }

    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _initial {
    final name = _user.fullName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    return name.substring(0, 1).toUpperCase();
  }

  Widget _buildAvatar() {
    Widget content;

    if (_localAvatarBytes != null) {
      content = Image.memory(_localAvatarBytes!, fit: BoxFit.cover);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      content = Image.network(
        _avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    } else {
      content = _avatarFallback();
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipOval(child: content),
          if (_isUploading)
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x88000000),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              color: const Color(0xFF1F7A5A),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Change profile photo',
                onPressed: _isUploading ? null : _chooseAvatar,
                icon: const Icon(Icons.camera_alt_outlined),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFE8EFE7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial,
          style: const TextStyle(
            color: Color(0xFF1F7A5A),
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFF7F7F2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: _buildAvatar()),
          const SizedBox(height: 16),
          Text(
            _user.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _user.email,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          Text(
            'Account',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _ProfileInfoTile(
                  icon: Icons.person_outline,
                  label: 'Full name',
                  value: _user.fullName,
                  onTap: _openEditName,
                ),
                const Divider(height: 1, indent: 56),
                _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _user.phone?.isNotEmpty == true
                      ? _user.phone!
                      : 'Not set',
                  onTap: _openEditPhone,
                ),
                const Divider(height: 1, indent: 56),
                _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _user.email,
                ),
                const Divider(height: 1, indent: 56),
                _ProfileInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Account type',
                  value: _user.role,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subscription',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFFB7791F),
              ),
              title: const Text('VIP Membership'),
              subtitle: const Text('View plans and subscription status'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const VipScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final editable = onTap != null;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1F7A5A)),
      title: Text(label),
      subtitle: Text(value),
      trailing: editable
          ? const Icon(Icons.edit_outlined, size: 20, color: Colors.black45)
          : null,
      onTap: onTap,
    );
  }
}

// ── Edit bottom sheet ──

class _EditFieldSheet extends StatefulWidget {
  const _EditFieldSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.maxLines,
    required this.maxLength,
    required this.onSave,
    this.keyboardType,
  });

  final String title;
  final String label;
  final String initialValue;
  final int maxLines;
  final int maxLength;
  final Future<AuthUser> Function(String value) onSave;
  final TextInputType? keyboardType;

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = await widget.onSave(value);
      if (!mounted) return;
      Navigator.of(context).pop<AuthUser>(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: widget.maxLines,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A5A),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
