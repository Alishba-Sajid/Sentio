import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:stress_detection_app/features/sessions/session_playback_screen.dart';
import 'package:stress_detection_app/services/session_service.dart';
import 'package:stress_detection_app/utils/session_date.dart';
import 'package:stress_detection_app/widgets/premium_scaffold.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _sessionService = SessionService();
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _sessionService.getMySessions();
      if (mounted) setState(() => _sessions = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAudioOnly(Map<String, dynamic> s) {
    final meta = s['phase_metadata'];
    return meta is Map && meta['audio_only'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('My recordings'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No recordings yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete a stress session to see it here.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      final created = SessionDate.formatListTile(
                        s['created_at']?.toString(),
                      );
                      final stress = s['self_reported_stress'] ?? '-';
                      final duration = s['duration_seconds'] ?? 0;
                      final audioOnly = _isAudioOnly(s);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SessionPlaybackScreen(session: s),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: AppTheme.premiumCardDecoration(),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.headerGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        audioOnly
                                            ? Icons.mic_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            created,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stress peak: $stress/10 • ${duration}s',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            audioOnly
                                                ? 'Tap to play audio'
                                                : 'Tap to play recording',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
