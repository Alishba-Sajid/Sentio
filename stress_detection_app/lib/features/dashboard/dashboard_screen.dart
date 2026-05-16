import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:stress_detection_app/features/auth/login_screen.dart';
import 'package:stress_detection_app/features/recording/recording_screen.dart';
import 'package:stress_detection_app/features/sessions/sessions_screen.dart';
import 'package:stress_detection_app/l10n/app_strings.dart';
import 'package:stress_detection_app/models/session_language.dart';
import 'package:stress_detection_app/services/auth_service.dart';
import 'package:stress_detection_app/widgets/premium_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _auth.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String get _firstName {
    final full = (_profile?['full_name'] as String?) ?? 'Student';
    return full.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PremiumScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const lang = SessionLanguage.english;

    return PremiumScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(height: 1.2),
                            children: [
                              TextSpan(
                                text: AppStrings.hello(lang),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: _firstName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const TextSpan(
                                text: ' 😊',
                                style: TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Log out',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.premiumCardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.headerGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?['full_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_profile?['department'] ?? ''} • Semester ${_profile?['semester'] ?? ''}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _profile?['email'] ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.premiumCardDecoration(
                          borderColor: AppTheme.primaryLight.withValues(
                            alpha: 0.28,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.headerGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PulseSense Premium',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'A calm baseline and a more intense pressure test for premium stress capture.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.researchSession(lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.researchDesc(lang),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ActionCard(
                        icon: Icons.videocam_rounded,
                        title: AppStrings.startStressTest(lang),
                        subtitle: AppStrings.startStressSub(lang),
                        gradient: AppTheme.headerGradient,
                        onTap: () async {
                          final saved = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordingScreen(),
                            ),
                          );
                          if (!context.mounted) return;
                          if (saved == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.savedSnack(lang)),
                                backgroundColor: AppTheme.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.play_circle_outline_rounded,
                        title: AppStrings.myRecordings(lang),
                        subtitle: AppStrings.myRecordingsSub(lang),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SessionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: AppTheme.premiumCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
