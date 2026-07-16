import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';

/// Thanh phát audio dùng chung cho chord/scale detail.
/// Tự xử lý cả URL tuyệt đối (http...) và relative (/uploads/...).
class AudioPlayerBar extends StatefulWidget {
  const AudioPlayerBar({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  late final AudioPlayer _player;
  late final String _resolvedUrl;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription? _onComplete;
  StreamSubscription? _onDuration;
  StreamSubscription? _onPosition;
  StreamSubscription? _onState;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _resolvedUrl = _resolveUrl(widget.audioUrl);

    _onComplete = _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    _onDuration = _player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _onPosition = _player.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _onState = _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoading = state == PlayerState.playing && _duration == Duration.zero;
      });
    });

    _preload();
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConfig.baseUrl}$url';
  }

  Future<void> _preload() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _player.setSource(UrlSource(_resolvedUrl));
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_hasError) {
      await _preload();
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else if (_position > Duration.zero && _duration > Duration.zero) {
        await _player.resume();
      } else {
        setState(() => _isLoading = true);
        await _player.play(UrlSource(_resolvedUrl));
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _seek(double fraction) async {
    if (_duration == Duration.zero) return;
    final ms = (fraction * _duration.inMilliseconds).toInt();
    await _player.seek(Duration(milliseconds: ms));
  }

  @override
  void dispose() {
    _onComplete?.cancel();
    _onDuration?.cancel();
    _onPosition?.cancel();
    _onState?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFB42318)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Could not load audio',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              IconButton(
                tooltip: 'Retry',
                icon: const Icon(Icons.refresh, color: Color(0xFF1F7A5A)),
                onPressed: _preload,
              ),
            ],
          ),
        ),
      );
    }

    final canSeek = _duration > Duration.zero;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _buildPlayButton(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: canSeek
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                        : 0,
                    activeColor: const Color(0xFF1F7A5A),
                    onChanged: canSeek ? _seek : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    if (_isLoading) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1F7A5A),
            ),
          ),
        ),
      );
    }

    return IconButton(
      iconSize: 40,
      color: const Color(0xFF1F7A5A),
      icon: Icon(
        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
      ),
      onPressed: _togglePlay,
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
