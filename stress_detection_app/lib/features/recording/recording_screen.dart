import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:record/record.dart';
import 'package:stress_detection_app/data/session_content.dart';
import 'package:stress_detection_app/features/recording/widgets/paragraph_card.dart';
import 'package:stress_detection_app/features/recording/widgets/shake_wrapper.dart';
import 'package:stress_detection_app/features/recording/widgets/stress_speedometer.dart';
import 'package:stress_detection_app/models/reading_paragraph.dart';
import 'package:stress_detection_app/models/session_language.dart';
import 'package:stress_detection_app/l10n/app_strings.dart';
import 'package:stress_detection_app/services/session_service.dart';
import 'package:stress_detection_app/widgets/premium_scaffold.dart';

enum RecordingPhase { idle, introduction, pressure, uploading, done }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _controller;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _initialized = false;
  bool _mediaLoading = false;
  bool _cameraEnabled = true;
  static const double _previewHeight = 240;
  bool _isFinishing = false;
  String? _audioRecordPath;

  RecordingPhase _phase = RecordingPhase.idle;
  SessionLanguage _language = SessionLanguage.english;

  int _secondsInPhase = 0;
  int _tierSeconds = 0;
  int _pressureTier = 0;
  int _totalSeconds = 0;
  int _introSeconds = 0;
  int _pressureSeconds = 0;

  Timer? _phaseTimer;
  Timer? _gaugeTimer;
  Timer? _panicTimer;

  String? _alertMessage;
  String? _countdownMessage;
  bool _showUrgentBorder = false;
  bool _redFlash = false;
  bool _shakeScreen = false;

  double _detectedStress = 2.0;
  double _peakDetectedStress = 2.0;
  int _lastLowStressPanicAt = -99;
  final _random = math.Random();

  final _sessionService = SessionService();
  String? _savedLocalPath;
  String? _uploadError;
  bool _uploadedToCloud = false;

  List<ReadingParagraph> get _paragraphBlocks =>
      SessionContent.paragraphs(_language);

  int get _currentTierDuration => SessionContent.durationForTier(_pressureTier);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _initMedia();
    if (mounted) setState(() => _initialized = true);
  }

  Future<String> _newAudioPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/session_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _setCameraEnabled(bool enabled) async {
    if (_phase != RecordingPhase.idle || enabled == _cameraEnabled) return;

    setState(() {
      _cameraEnabled = enabled;
      _mediaLoading = true;
    });

    await _controller?.dispose();
    _controller = null;

    try {
      await _initMedia();
    } finally {
      if (mounted) setState(() => _mediaLoading = false);
    }
  }

  Future<void> _initMedia() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted && !_initialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == SessionLanguage.urdu
                  ? 'مائیکروفون کی اجازت درکار ہے۔'
                  : 'Microphone permission is required.',
            ),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (!_cameraEnabled) {
      return;
    }

    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == SessionLanguage.urdu
                  ? 'ویڈیو کے لیے کیمرے کی اجازت درکار ہے۔'
                  : 'Camera permission is required for video mode.',
            ),
          ),
        );
        setState(() => _cameraEnabled = false);
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == SessionLanguage.urdu
                  ? 'کیمرہ خرابی: $e'
                  : 'Camera error: $e',
            ),
          ),
        );
        setState(() => _cameraEnabled = false);
      }
    }
  }

  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    _secondsInPhase = 0;
    _tierSeconds = 0;
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsInPhase++;
        _totalSeconds++;
        if (_phase == RecordingPhase.pressure) {
          _tierSeconds++;
          _pressureSeconds = _secondsInPhase;
        }
      });
      _onPhaseTick();
    });
  }

  void _startGaugeTimer() {
    _gaugeTimer?.cancel();
    _gaugeTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted || _phase != RecordingPhase.pressure) return;
      _updateDetectedStress();
    });
  }

  void _startPanicTimer() {
    _panicTimer?.cancel();
    final interval = SessionContent.panicIntervalSeconds(_pressureTier);
    _panicTimer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!mounted || _phase != RecordingPhase.pressure) return;
      _firePanicAlert();
    });
  }

  void _updateDetectedStress() {
    final timeFactor = _secondsInPhase / SessionContent.pressureDurationSeconds;
    final tierBoost = [0.0, 2.2, 4.5][_pressureTier.clamp(0, 2)];
    final target =
        2.0 + timeFactor * 5.0 + tierBoost + _random.nextDouble() * 1.4;
    final delta = (target - _detectedStress) * (0.32 + _pressureTier * 0.08);
    var next = _detectedStress + delta + (_random.nextDouble() - 0.4);

    if (_random.nextDouble() < 0.1 + _pressureTier * 0.05) {
      next = _detectedStress + 2.0 + _random.nextDouble() * 2;
    }

    next = next.clamp(1.0, 10.0);
    _peakDetectedStress = math.max(_peakDetectedStress, next);

    setState(() => _detectedStress = next);

    final lowThreshold = _pressureTier == 0
        ? 3.5
        : (_pressureTier == 1 ? 4.5 : 5.5);
    if (next < lowThreshold &&
        _tierSeconds > 3 &&
        _totalSeconds - _lastLowStressPanicAt > 5) {
      _lastLowStressPanicAt = _totalSeconds;
      _fireLowStressPanic();
    }
  }

  void _fireLowStressPanic() {
    final alerts = SessionContent.lowStressAlerts(_language);
    setState(() {
      _alertMessage = alerts[_random.nextInt(alerts.length)];
      _showUrgentBorder = true;
      _redFlash = true;
    });
    _triggerShake();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _redFlash = false);
    });
  }

  void _firePanicAlert({bool tierSpecific = false}) {
    final pool = tierSpecific
        ? SessionContent.tierPanicAlerts(_language, _pressureTier)
        : [
            ...SessionContent.panicAlerts(_language),
            ...SessionContent.tierPanicAlerts(_language, _pressureTier),
          ];
    setState(() {
      _alertMessage = pool[_random.nextInt(pool.length)];
      _redFlash = true;
      if (_pressureTier >= 1) _showUrgentBorder = true;
    });
    _triggerShake();
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _redFlash = false);
    });
  }

  void _triggerShake() {
    setState(() => _shakeScreen = true);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _shakeScreen = false);
    });
  }

  void _onPhaseTick() {
    if (_phase == RecordingPhase.introduction) {
      if (_secondsInPhase >= SessionContent.introDurationSeconds) {
        _beginPressurePhase();
      }
      return;
    }

    if (_phase == RecordingPhase.pressure) {
      // Countdown before next paragraph (last 2 seconds of each tier window)
      final tierDuration = _currentTierDuration;
      final remainingInTier = tierDuration - _tierSeconds;
      if (remainingInTier <= 3 &&
          remainingInTier > 0 &&
          _pressureTier < _paragraphBlocks.length - 1) {
        setState(() {
          _countdownMessage = SessionContent.nextParagraphCountdown(
            _language,
            remainingInTier,
          );
        });
        if (remainingInTier <= 2) {
          _redFlash = true;
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) setState(() => _redFlash = false);
          });
        }
      } else if (_countdownMessage != null && remainingInTier > 3) {
        setState(() => _countdownMessage = null);
      }

      final half = (_currentTierDuration / 2).floor();
      if (_tierSeconds == half && half > 0) {
        _firePanicAlert(tierSpecific: true);
      }

      if (_tierSeconds == 1 && _pressureTier > 0) {
        _firePanicAlert(tierSpecific: true);
        HapticFeedback.heavyImpact();
      }

      if (_tierSeconds >= _currentTierDuration) {
        if (_pressureTier < _paragraphBlocks.length - 1) {
          _advanceParagraph();
        } else if (_secondsInPhase >= SessionContent.pressureDurationSeconds) {
          _finishSession();
        }
      }

      if (_secondsInPhase >= SessionContent.pressureDurationSeconds) {
        _finishSession();
      }
    }
  }

  void _advanceParagraph() {
    setState(() {
      _pressureTier++;
      _tierSeconds = 0;
      _countdownMessage = null;
      _alertMessage = SessionContent.tierAdvanceMessage(
        _language,
        _pressureTier,
      );
      _showUrgentBorder = _pressureTier >= 1;
      _redFlash = true;
    });
    _triggerShake();
    HapticFeedback.heavyImpact();
    _detectedStress = math.min(
      10.0,
      _detectedStress + 1.8 + _pressureTier * 0.5,
    );
    _startPanicTimer();
    _firePanicAlert(tierSpecific: true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _redFlash = false);
    });
  }

  Future<void> _startSession() async {
    try {
      if (_cameraEnabled) {
        if (_controller == null || !_controller!.value.isInitialized) return;
        await _controller!.startVideoRecording();
      } else {
        _audioRecordPath = await _newAudioPath();
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioRecordPath!,
        );
      }
      setState(() {
        _phase = RecordingPhase.introduction;
        _alertMessage = null;
        _countdownMessage = null;
        _showUrgentBorder = false;
        _pressureTier = 0;
        _tierSeconds = 0;
        _totalSeconds = 0;
        _introSeconds = 0;
        _pressureSeconds = 0;
        _detectedStress = 2.0;
        _peakDetectedStress = 2.0;
      });
      _startPhaseTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _beginPressurePhase() async {
    _phaseTimer?.cancel();
    setState(() {
      _introSeconds = _secondsInPhase;
      _phase = RecordingPhase.pressure;
      _secondsInPhase = 0;
      _tierSeconds = 0;
      _pressureTier = 0;
      _alertMessage = AppStrings.pressureStartAlert(_language);
    });
    HapticFeedback.mediumImpact();
    _startPhaseTimer();
    _startGaugeTimer();
    _startPanicTimer();
    _firePanicAlert();
  }

  Future<void> _finishSession() async {
    if (_isFinishing) return;
    _isFinishing = true;

    _phaseTimer?.cancel();
    _gaugeTimer?.cancel();
    _panicTimer?.cancel();

    if (_cameraEnabled && _controller == null) {
      _isFinishing = false;
      return;
    }

    setState(() => _phase = RecordingPhase.uploading);

    File? saved;
    try {
      if (_cameraEnabled) {
        XFile? raw;
        if (_controller!.value.isRecordingVideo) {
          raw = await _controller!.stopVideoRecording();
        }
        if (raw != null) {
          final dir = await getApplicationDocumentsDirectory();
          final localPath =
              '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.mp4';
          saved = await File(raw.path).copy(localPath);
        }
      } else {
        final path = await _audioRecorder.stop();
        if (path != null) {
          saved = File(path);
        }
      }

      if (saved != null) {
        if (mounted) setState(() => _savedLocalPath = saved!.path);
      } else {
        throw Exception('No recording was captured.');
      }

      if (!mounted) return;

      _introSeconds = _introSeconds == 0
          ? SessionContent.introDurationSeconds
          : _introSeconds;
      _pressureSeconds = _pressureSeconds == 0
          ? _secondsInPhase
          : _pressureSeconds;

      final result = await _sessionService.saveSession(
        mediaFile: saved,
        audioOnly: !_cameraEnabled,
        detectedStressPeak: _peakDetectedStress.round().clamp(1, 10),
        detectedStressEnd: _detectedStress.round().clamp(1, 10),
        durationSeconds: _totalSeconds,
        introductionSeconds: _introSeconds,
        pressureSeconds: _pressureSeconds,
        pressureTier: _pressureTier + 1,
        languageCode: _language.code,
        phaseMetadata: {
          'paragraphs': _paragraphBlocks
              .map(
                (p) => {
                  'instruction': p.instruction,
                  'title': p.title,
                  'body': p.body,
                },
              )
              .toList(),
          'final_tier': _pressureTier,
          'peak_gauge': _peakDetectedStress,
          'end_gauge': _detectedStress,
        },
      );

      if (!mounted) return;

      setState(() {
        _phase = RecordingPhase.done;
        _uploadedToCloud = result.uploadedToCloud;
        _uploadError = result.errorMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_savedLocalPath != null) {
          _phase = RecordingPhase.done;
          _uploadedToCloud = false;
          _uploadError = e.toString();
        } else {
          _phase = RecordingPhase.pressure;
          _isFinishing = false;
        }
      });
      if (_savedLocalPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      _isFinishing = false;
    }
  }

  Future<void> _cancelEarly() async {
    _phaseTimer?.cancel();
    _gaugeTimer?.cancel();
    _panicTimer?.cancel();
    if (_cameraEnabled && _controller?.value.isRecordingVideo == true) {
      await _controller!.stopVideoRecording();
    } else if (!_cameraEnabled && await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _buildPreviewArea(bool isActive) {
    if (!_cameraEnabled) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.mic : Icons.mic_none,
              size: 72,
              color: isActive ? AppTheme.danger : Colors.white54,
            ),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? AppStrings.recordingAudio(_language)
                  : AppStrings.audioOnlyPreview(_language),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (_controller != null && _controller!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize?.height ?? 400,
          height: _controller!.value.previewSize?.width ?? 300,
          child: CameraPreview(_controller!),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildPreviewBox(bool isActive) {
    return SizedBox(
      height: _previewHeight,
      width: double.infinity,
      child: ShakeWrapper(
        shake: _shakeScreen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: _showUrgentBorder
                ? Border.all(color: AppTheme.danger, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreviewArea(isActive),
                if (_mediaLoading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.switchingCamera(_language),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _phaseTitle {
    switch (_phase) {
      case RecordingPhase.idle:
        return AppStrings.phaseReady(_language);
      case RecordingPhase.introduction:
        return AppStrings.phaseIntro(_language);
      case RecordingPhase.pressure:
        return AppStrings.phasePressure(_language);
      case RecordingPhase.uploading:
        return AppStrings.phaseSaving(_language);
      case RecordingPhase.done:
        return AppStrings.phaseDone(_language);
    }
  }

  int get _phaseRemaining {
    if (_phase == RecordingPhase.introduction) {
      return SessionContent.introDurationSeconds - _secondsInPhase;
    }
    if (_phase == RecordingPhase.pressure) {
      return SessionContent.pressureDurationSeconds - _secondsInPhase;
    }
    return 0;
  }

  Widget _buildCompactPhaseBar(bool isActive) {
    final isIntro = _phase == RecordingPhase.introduction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _phaseTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isIntro ? AppTheme.success : AppTheme.danger,
              ),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isIntro ? AppTheme.success : AppTheme.danger)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_phaseRemaining.clamp(0, 999)}s',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIntro ? AppTheme.success : AppTheme.danger,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPressureAlertsPanel() {
    if (_phase != RecordingPhase.pressure) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          if (_alertMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFF9D174D)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.danger.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _alertMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_countdownMessage != null) ...[
            if (_alertMessage != null) const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
              ),
              child: Text(
                _countdownMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (_alertMessage == null && _countdownMessage == null)
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _gaugeTimer?.cancel();
    _panicTimer?.cancel();
    _controller?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const PremiumScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isActive =
        _phase == RecordingPhase.introduction ||
        _phase == RecordingPhase.pressure;
    final canStop = isActive && !_isFinishing;
    final isRtl = _language == SessionLanguage.urdu;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(AppStrings.stressSessionTitle(_language)),
        leading: _phase == RecordingPhase.idle || _phase == RecordingPhase.done
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Column(
              children: [
                if (isActive) _buildCompactPhaseBar(isActive),
                if (_phase == RecordingPhase.pressure) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                    child: StressSpeedometer(
                      level: _detectedStress,
                      label: AppStrings.detectedStressLabel(_language),
                    ),
                  ),
                  _buildPressureAlertsPanel(),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _buildPreviewBox(isActive),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        if (_phase == RecordingPhase.introduction)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.premiumCardDecoration(
                                borderColor: AppTheme.success.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: Text(
                                SessionContent.introPrompt(_language),
                                style: const TextStyle(
                                  height: 1.5,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        if (_phase == RecordingPhase.pressure) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${AppStrings.sectionLabel(_language)} ${_pressureTier + 1}/${_paragraphBlocks.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_currentTierDuration - _tierSeconds}s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ParagraphCard(
                              paragraph: _paragraphBlocks[
                                  _pressureTier.clamp(
                                    0,
                                    _paragraphBlocks.length - 1,
                                  )],
                              language: _language,
                              urgent: _showUrgentBorder,
                              complexityLabel: SessionContent.complexityLabel(
                                _language,
                                _pressureTier,
                              ),
                              tierIndex: _pressureTier,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _tierSeconds / _currentTierDuration,
                                backgroundColor: Colors.grey.shade200,
                                color: AppTheme.danger,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_phase == RecordingPhase.uploading)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  _savedLocalPath != null
                                      ? AppStrings.uploading(_language)
                                      : AppStrings.processing(_language),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        if (_phase == RecordingPhase.done)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  _uploadedToCloud
                                      ? Icons.cloud_done
                                      : Icons.save,
                                  color: _uploadedToCloud
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _uploadedToCloud
                                      ? AppStrings.savedCloud(_language)
                                      : AppStrings.savedLocal(_language),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_uploadError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _uploadError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.danger,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.peakStress(
                                    _language,
                                    _peakDetectedStress,
                                  ),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, _uploadedToCloud),
                                  child: Text(
                                    AppStrings.backDashboard(_language),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_phase == RecordingPhase.idle)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.premiumCardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.sessionLanguage(_language),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SegmentedButton<SessionLanguage>(
                                    segments: SessionLanguage.values
                                        .map(
                                          (l) => ButtonSegment(
                                            value: l,
                                            label: Text(l.label),
                                          ),
                                        )
                                        .toList(),
                                    selected: {_language},
                                    onSelectionChanged: (v) =>
                                        setState(() => _language = v.first),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppStrings.recordWithCamera(
                                            _language,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _cameraEnabled,
                                        onChanged: _mediaLoading
                                            ? null
                                            : _setCameraEnabled,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _cameraEnabled
                                        ? AppStrings.cameraOnHint(_language)
                                        : AppStrings.cameraOffHint(_language),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_phase == RecordingPhase.idle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _startSession,
                          icon: Icon(
                            _cameraEnabled ? Icons.videocam : Icons.mic,
                          ),
                          label: Text(AppStrings.startSession(_language)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.sessionFlowHint(_language),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canStop)
                        ElevatedButton.icon(
                          onPressed: _finishSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger,
                          ),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text(AppStrings.stopSave(_language)),
                        ),
                      if (isActive && !_isFinishing)
                        TextButton(
                          onPressed: _cancelEarly,
                          child: Text(
                            AppStrings.cancelSession(_language),
                            style: const TextStyle(color: AppTheme.danger),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_redFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppTheme.danger.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
