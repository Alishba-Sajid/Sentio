import 'package:stress_detection_app/models/session_language.dart';

class AppStrings {
  static String t(SessionLanguage lang, String en, String ur) =>
      lang == SessionLanguage.urdu ? ur : en;

  // Recording
  static String stressSessionTitle(SessionLanguage lang) =>
      t(lang, 'Stress session', 'دباؤ سیشن');

  static String phaseReady(SessionLanguage lang) => t(lang, 'Ready', 'تیار');
  static String phaseIntro(SessionLanguage lang) =>
      t(lang, 'Baseline — Introduction', 'بنیادی — تعارف');
  static String phasePressure(SessionLanguage lang) =>
      t(lang, 'Pressure — Read aloud', 'دباؤ — بلند آواز میں پڑھیں');
  static String phaseSaving(SessionLanguage lang) => t(lang, 'Saving…', 'محفوظ ہو رہا ہے…');
  static String phaseDone(SessionLanguage lang) =>
      t(lang, 'Session complete', 'سیشن مکمل');

  static String pressureStartAlert(SessionLanguage lang) =>
      t(lang, 'Pressure phase — read the story passage aloud!', 'دباؤ کا مرحلہ — کہانی بلند آواز میں پڑھیں!');

  static String sessionLanguage(SessionLanguage lang) =>
      t(lang, 'Session language', 'سیشن کی زبان');

  static String recordWithCamera(SessionLanguage lang) =>
      t(lang, 'Record with camera', 'کیمرے سے ریکارڈ کریں');

  static String cameraOnHint(SessionLanguage lang) =>
      t(lang, 'Video and audio will be recorded.', 'ویڈیو اور آواز ریکارڈ ہوگی۔');

  static String cameraOffHint(SessionLanguage lang) =>
      t(lang, 'Audio only — camera stays off.', 'صرف آواز — کیمرہ بند رہے گا۔');

  static String startSession(SessionLanguage lang) =>
      t(lang, 'Start recording session', 'ریکارڈنگ شروع کریں');

  static String sessionFlowHint(SessionLanguage lang) => t(
        lang,
        '25s intro → ~66s pressure (18s easy → 20s medium → 28s hard)',
        '۲۵ سیکنڈ تعارف → ~۶۶ سیکنڈ دباؤ (۱۸ آسان → ۲۰ درمیانہ → ۲۸ مشکل)',
      );

  static String stopSave(SessionLanguage lang) =>
      t(lang, 'Stop & save session', 'روکیں اور محفوظ کریں');

  static String cancelSession(SessionLanguage lang) =>
      t(lang, 'Cancel session', 'سیشن منسوخ کریں');

  static String sectionLabel(SessionLanguage lang) => t(lang, 'Section', 'حصہ');

  static String recordingAudio(SessionLanguage lang) =>
      t(lang, 'Recording audio…', 'آواز ریکارڈ ہو رہی ہے…');

  static String audioOnlyPreview(SessionLanguage lang) =>
      t(lang, 'Audio only — camera off', 'صرف آواز — کیمرہ بند');

  static String uploading(SessionLanguage lang) =>
      t(lang, 'Recording saved on device. Uploading…', 'ریکارڈنگ محفوظ۔ اپ لوڈ ہو رہی ہے…');

  static String processing(SessionLanguage lang) =>
      t(lang, 'Processing recording…', 'ریکارڈنگ پروسیس ہو رہی ہے…');

  static String savedCloud(SessionLanguage lang) =>
      t(lang, 'Session saved to cloud.', 'سیشن کلاؤڈ پر محفوظ ہو گیا۔');

  static String savedLocal(SessionLanguage lang) =>
      t(lang, 'Recording saved on your phone only.', 'ریکارڈنگ صرف فون پر محفوظ ہے۔');

  static String peakStress(SessionLanguage lang, double peak) => t(
        lang,
        'Peak detected stress: ${peak.toStringAsFixed(1)}/10',
        'زیادہ سے زیادہ دباؤ: ${peak.toStringAsFixed(1)}/10',
      );

  static String backDashboard(SessionLanguage lang) =>
      t(lang, 'Back to dashboard', 'ڈیش بورڈ پر واپس');

  static String detectedStressLabel(SessionLanguage lang) =>
      t(lang, 'Detected stress', 'پتہ چلا دباؤ');

  static String switchingCamera(SessionLanguage lang) =>
      t(lang, 'Preparing camera…', 'کیمرہ تیار ہو رہا ہے…');

  // Dashboard
  static String hello(SessionLanguage lang) => t(lang, 'Hello,', 'سلام،');
  static String researchSession(SessionLanguage lang) =>
      t(lang, 'Research session', 'تحقیقی سیشن');
  static String researchDesc(SessionLanguage lang) => t(
        lang,
        'Record a calm introduction, then read story passages under timed pressure.',
        'پرسکون تعارف دیں، پھر وقت کے دباؤ میں کہانی کے حصے پڑھیں۔',
      );
  static String startStressTest(SessionLanguage lang) =>
      t(lang, 'Start stress test', 'دباؤ ٹیسٹ شروع کریں');
  static String startStressSub(SessionLanguage lang) => t(
        lang,
        'Baseline intro, then escalating story passages',
        'بنیادی تعارف، پھر مشکل ہوتی کہانی',
      );
  static String myRecordings(SessionLanguage lang) =>
      t(lang, 'My recordings', 'میری ریکارڈنگز');
  static String myRecordingsSub(SessionLanguage lang) =>
      t(lang, 'Play and review your sessions', 'سیشنز سنیں اور دیکھیں');

  static String savedSnack(SessionLanguage lang) =>
      t(lang, 'Session saved successfully.', 'سیشن کامیابی سے محفوظ ہوا۔');
}
