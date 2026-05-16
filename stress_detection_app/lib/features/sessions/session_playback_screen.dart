import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:stress_detection_app/services/session_service.dart';
import 'package:stress_detection_app/utils/session_date.dart';
import 'package:video_player/video_player.dart';

class SessionPlaybackScreen extends StatefulWidget {
  const SessionPlaybackScreen({super.key, required this.session});

  final Map<String, dynamic> session;

  @override
  State<SessionPlaybackScreen> createState() => _SessionPlaybackScreenState();
}

class _SessionPlaybackScreenState extends State<SessionPlaybackScreen> {
  final _sessionService = SessionService();
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  bool get _audioOnly {
    final meta = widget.session['phase_metadata'];
    return meta is Map && meta['audio_only'] == true;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final url = await _sessionService.getSignedPlaybackUrl(widget.session);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final created = SessionDate.formatListTile(
      widget.session['created_at']?.toString(),
    );
    final stress = widget.session['self_reported_stress'] ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load recording:\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            created,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Peak stress gauge: $stress/10',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          if (_audioOnly)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Audio-only session',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _controller != null && _controller!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (_controller != null) ...[
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 48,
                              icon: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: AppTheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller!.value.isPlaying
                                      ? _controller!.pause()
                                      : _controller!.play();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
