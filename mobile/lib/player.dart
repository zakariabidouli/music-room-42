// Shared Deezer preview player. Deezer remains metadata/preview-only; queue
// ranking, voting, and collaborative state all stay on the backend.
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PreviewPlayer extends ChangeNotifier {
  PreviewPlayer._() {
    _positionSub = _p.onPositionChanged.listen((position) {
      _position = _clampPosition(position);
      notifyListeners();
    });
    _durationSub = _p.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
    _stateSub = _p.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        playing = true;
        _isBuffering = false;
      } else if (state == PlayerState.paused) {
        playing = false;
        _isBuffering = false;
      } else if (state == PlayerState.completed) {
        playing = false;
        _isBuffering = false;
        _position = _duration;
      } else if (state == PlayerState.stopped) {
        playing = false;
        _isBuffering = false;
      }
      notifyListeners();
    });
    _completeSub = _p.onPlayerComplete.listen((_) {
      playing = false;
      _isBuffering = false;
      _position = _duration;
      notifyListeners();
    });
  }

  static final PreviewPlayer instance = PreviewPlayer._();

  final AudioPlayer _p = AudioPlayer();
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;

  String? currentUrl;
  Map? currentMeta;
  bool playing = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;

  bool get isBuffering => _isBuffering;
  bool get hasTrack => currentUrl != null && currentMeta != null;
  bool get isSeekable => hasTrack && _duration > Duration.zero;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  double get progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  Duration _clampPosition(Duration value) {
    if (_duration <= Duration.zero) return Duration.zero;
    final milliseconds = value.inMilliseconds.clamp(0, _duration.inMilliseconds);
    return Duration(milliseconds: milliseconds);
  }

  Future<void> playTrack(Map track, {bool restart = false}) async {
    final rawUrl = track['previewUrl'];
    final url = rawUrl?.toString().trim() ?? '';
    if (url.isEmpty || url == 'null') {
      _errorMessage = 'No preview is available for this track.';
      notifyListeners();
      return;
    }

    final isSameTrack = currentUrl == url && currentMeta != null;
    if (isSameTrack && playing && !restart) {
      await pause();
      return;
    }

    _errorMessage = null;
    if (!isSameTrack) {
      await _p.stop();
      currentUrl = url;
      currentMeta = Map<String, dynamic>.from(track);
      _position = Duration.zero;
      _duration = Duration.zero;
      _isBuffering = true;
      notifyListeners();
    }

    try {
      if (isSameTrack) {
        if (restart || _position >= _duration) {
          await _p.seek(Duration.zero);
          _position = Duration.zero;
        }
        await _p.resume();
      } else {
        await _p.play(UrlSource(url));
      }
      playing = true;
      _isBuffering = false;
      _errorMessage = null;
    } catch (error) {
      playing = false;
      _isBuffering = false;
      _errorMessage = 'Preview could not be played. Check your connection.';
      debugPrint('PreviewPlayer.playTrack: $error');
    }
    notifyListeners();
  }

  Future<void> pause() async {
    if (!hasTrack) return;
    try {
      await _p.pause();
      playing = false;
      _isBuffering = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Playback could not be paused.';
      debugPrint('PreviewPlayer.pause: $error');
      notifyListeners();
    }
  }

  Future<void> toggleCurrent() async {
    if (currentMeta == null) return;
    await playTrack(currentMeta!, restart: !playing);
  }

  Future<void> seek(Duration value) async {
    if (!isSeekable) return;
    final target = _clampPosition(value);
    try {
      await _p.seek(target);
      _position = target;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'That preview position is not available.';
      debugPrint('PreviewPlayer.seek: $error');
      notifyListeners();
    }
  }

  Future<void> skipBy(Duration offset) async {
    if (!isSeekable) return;
    await seek(_position + offset);
  }

  Future<void> stop() async {
    try {
      await _p.stop();
    } catch (error) {
      debugPrint('PreviewPlayer.stop: $error');
    }
    playing = false;
    _isBuffering = false;
    currentUrl = null;
    currentMeta = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _durationSub.cancel();
    _stateSub.cancel();
    _completeSub.cancel();
    _p.dispose();
    super.dispose();
  }
}

String formatPlaybackTime(Duration value) {
  final safeSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
  final minutes = safeSeconds ~/ 60;
  final seconds = safeSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class PreviewButton extends StatelessWidget {
  final Map track;
  final bool showLabel;

  const PreviewButton(this.track, {this.showLabel = false, super.key});

  @override
  Widget build(BuildContext context) {
    final url = track['previewUrl']?.toString().trim();
    if (url == null || url.isEmpty || url == 'null') {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: PreviewPlayer.instance,
      builder: (context, _) {
        final player = PreviewPlayer.instance;
        final isCurrent = player.currentUrl == url;
        final isLoading = isCurrent && player.isBuffering;
        final isPlaying = isCurrent && player.playing;
        final semanticLabel = isPlaying
            ? 'Pause ${track['title'] ?? 'track'} preview'
            : 'Play ${track['title'] ?? 'track'} preview';

        if (showLabel) {
          return FilledButton.tonalIcon(
            onPressed: isLoading ? null : () => player.playTrack(track),
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(isPlaying ? 'Pause preview' : 'Play preview'),
          );
        }

        return IconButton(
          tooltip: semanticLabel,
          onPressed: isLoading ? null : () => player.playTrack(track),
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 34,
                ),
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}