import 'package:stress_detection_app/models/reading_paragraph.dart';
import 'package:stress_detection_app/models/session_language.dart';

class SessionContent {
  static const int introDurationSeconds = 25;

  /// Tier 1 = simple (shortest), tier 2 = medium, tier 3 = hardest (most time to read dense text).
  static const List<int> paragraphDurationsSeconds = [18, 20, 28];

  static int durationForTier(int tier) =>
      paragraphDurationsSeconds[tier.clamp(0, paragraphDurationsSeconds.length - 1)];

  static int get pressureDurationSeconds =>
      paragraphDurationsSeconds.fold(0, (sum, n) => sum + n);

  /// Panic alerts fire more often as complexity rises.
  static int panicIntervalSeconds(int tier) {
    switch (tier.clamp(0, 2)) {
      case 0:
        return 8;
      case 1:
        return 5;
      default:
        return 3;
    }
  }

  static String complexityLabel(SessionLanguage lang, int tier) {
    switch (tier.clamp(0, 2)) {
      case 0:
        return lang == SessionLanguage.urdu ? 'آسان' : 'Easy';
      case 1:
        return lang == SessionLanguage.urdu ? 'درمیانہ' : 'Medium';
      default:
        return lang == SessionLanguage.urdu ? 'مشکل' : 'Hard';
    }
  }

  static String introPrompt(SessionLanguage lang) {
    switch (lang) {
      case SessionLanguage.urdu:
        return 'اپنا مختصر تعارف دیں — نام، شعبہ، اور ایک شوق۔ قدرتی انداز میں بولیں۔ یہ آپ کی بے دباؤ (بنیادی) ریکارڈنگ ہے۔';
      case SessionLanguage.english:
        return 'Introduce yourself briefly — your name, department, and one hobby. Speak naturally. This is your baseline (stress-free) recording.';
    }
  }

  static List<ReadingParagraph> paragraphs(SessionLanguage lang) {
    switch (lang) {
      case SessionLanguage.urdu:
        return const [
          ReadingParagraph(
            instruction: 'یہ آسان حصہ بلند آواز میں پڑھیں',
            title: 'روشنی کا مینار — پہلا باب',
            body:
                'سارہ صبح سویرے اٹھی۔ سمندر پرسکون تھا۔ اس نے ناشتہ کیا اور باہر چہل قدمی کی۔ چڑیاں گانا گا رہی تھیں۔ آج کا دن اچھا تھا۔',
          ),
          ReadingParagraph(
            instruction: 'بغیر رکے پڑھیں — رفتار بڑھائیں',
            title: 'روشنی کا مینار — دوسرا باب',
            body:
                'دوپہر تک ہوا تیز ہو گئی۔ سارہ نے سوچا کہ کیا سامان کافی ہے اور کیا ریڈیو کام کرے گا۔ اسے لگا کہ جزیرے پر تنہا رہنے کا فیصلہ شاید مشکل ثابت ہو سکتا ہے، مگر وہ پھر بھی تیار رہنے کی کوشش کرتی رہی۔',
          ),
          ReadingParagraph(
            instruction: 'آخری مشکل حصہ — فوراً اور صاف پڑھیں',
            title: 'روشنی کا مینار — تیسرا باب',
            body:
                'طوفان کی آمد فوری ترجیحات طے کرنے کا مطالبہ کرتی ہے: بارومیٹر کی تیزی سے گرنے کی تصدیق، متضاد پیشن گوئیوں کا تطبیق، ہنگامی منصوبوں کا اعلان، اور اس ماحول میں جہاں کم نظر آنا، بڑھتی آوازیں، اور ہر سیکنڈ میں درستگی لازم ہو، ذہن مسلسل دباؤ میں کام کرتا ہے۔',
          ),
        ];
      case SessionLanguage.english:
        return const [
          ReadingParagraph(
            instruction: 'Easy section — read aloud clearly',
            title: 'The Lighthouse — Chapter One',
            body:
                'Maya woke up early. The sea was calm. She ate breakfast and walked outside. Birds were singing. It was a peaceful morning.',
          ),
          ReadingParagraph(
            instruction: 'Medium section — keep going, do not pause',
            title: 'The Lighthouse — Chapter Two',
            body:
                'By afternoon the wind grew stronger. Maya wondered if the supplies would last and whether the radio would still work. She began to doubt whether staying alone on the island had been a wise choice, yet she tried to stay focused.',
          ),
          ReadingParagraph(
            instruction: 'Hard section — read fast and loud',
            title: 'The Lighthouse — Chapter Three',
            body:
                'The storm’s approach demanded immediate prioritization: corroborate the barometer’s plunge, reconcile contradictory forecasts, articulate contingency protocols, and suppress visceral apprehension while visibility collapses, acoustics intensify, and every second punishes hesitation with irreversible consequence.',
          ),
        ];
    }
  }

  static String tierAdvanceMessage(SessionLanguage lang, int nextIndex) {
    final n = nextIndex + 1;
    final level = complexityLabel(lang, nextIndex);
    switch (lang) {
      case SessionLanguage.urdu:
        return 'حصہ $n/3 ($level) — ابھی پڑھیں!';
      case SessionLanguage.english:
        return 'Section $n/3 ($level) — READ NOW!';
    }
  }

  static String nextParagraphCountdown(SessionLanguage lang, int seconds) {
    switch (lang) {
      case SessionLanguage.urdu:
        return 'مشکل تر حصہ $seconds سیکنڈ میں…';
      case SessionLanguage.english:
        return 'Harder section in ${seconds}s…';
    }
  }

  static List<String> lowStressAlerts(SessionLanguage lang) {
    switch (lang) {
      case SessionLanguage.urdu:
        return [
          '⚠️ دباؤ کم ہے — تیز اور بلند پڑھیں!',
          '🚨 آپ اچھا نہیں کر رہے — فوراً تیز بولیں!',
          '❌ پروفائل کم دباؤ دکھا رہی ہے — پریشان ہو کر پڑھیں!',
        ];
      case SessionLanguage.english:
        return [
          '⚠️ Stress too LOW — read louder and faster!',
          '🚨 You are NOT performing well — speed up NOW!',
          '❌ Gauge shows low stress — show more urgency!',
        ];
    }
  }

  static List<String> panicAlerts(SessionLanguage lang) {
    switch (lang) {
      case SessionLanguage.urdu:
        return [
          '🚨 وقت ختم ہو رہا ہے!',
          '⚠️ رکیں نہیں — پڑھتے رہیں!',
          '🔴 غلطی قابل قبول نہیں!',
          '⏰ ابھی تیز کریں!',
          '❗ اگلا حصہ مشکل تر ہوگا — تیار رہیں!',
        ];
      case SessionLanguage.english:
        return [
          '🚨 Time is running out!',
          '⚠️ Do NOT pause — keep reading!',
          '🔴 Mistakes are NOT acceptable!',
          '⏰ Speed up RIGHT NOW!',
          '❗ Next section is HARDER — stay ready!',
        ];
    }
  }

  static List<String> tierPanicAlerts(SessionLanguage lang, int tier) {
    switch (tier) {
      case 0:
        return lang == SessionLanguage.urdu
            ? ['📖 آسان حصہ — لیکن رفتار برقرار رکھیں']
            : ['📖 Easy section — but keep your pace up'];
      case 1:
        return lang == SessionLanguage.urdu
            ? [
                '⚠️ درمیانہ دباؤ — الفاظ چھوڑیں نہیں!',
                '⏱️ وقت تیزی سے گزر رہا ہے!',
              ]
            : [
                '⚠️ Medium pressure — do NOT skip words!',
                '⏱️ Time is moving faster now!',
              ];
      default:
        return lang == SessionLanguage.urdu
            ? [
                '🔴 سب سے مشکل حصہ — فوراً پڑھیں!',
                '🚨 رکنا منع ہے — آواز بلند کریں!',
                '❌ ہر لمحہ شمار ہو رہا ہے!',
              ]
            : [
                '🔴 HARDEST section — read NOW!',
                '🚨 Do NOT stop — raise your voice!',
                '❌ Every second is being recorded!',
              ];
    }
  }
}
