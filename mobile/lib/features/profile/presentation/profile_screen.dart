import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_api.dart';
import '../data/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final ProfileApi _profileApi;

  String? _avatarUrl;
  Uint8List? _localAvatarBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi(ApiClient());
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
    final name = widget.user.fullName.trim();

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
            widget.user.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
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
                  value: widget.user.fullName,
                ),
                const Divider(height: 1, indent: 56),
                _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.user.email,
                ),
                const Divider(height: 1, indent: 56),
                _ProfileInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Account type',
                  value: widget.user.role,
                ),
              ],
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1F7A5A)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
