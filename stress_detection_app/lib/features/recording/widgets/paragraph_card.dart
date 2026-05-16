import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:stress_detection_app/models/reading_paragraph.dart';
import 'package:stress_detection_app/models/session_language.dart';

class ParagraphCard extends StatelessWidget {
  const ParagraphCard({
    super.key,
    required this.paragraph,
    required this.language,
    required this.urgent,
    required this.complexityLabel,
    required this.tierIndex,
    this.compact = false,
  });

  final ReadingParagraph paragraph;
  final SessionLanguage language;
  final bool urgent;
  final String complexityLabel;
  final int tierIndex;
  final bool compact;

  Color get _complexityColor {
    switch (tierIndex) {
      case 0:
        return AppTheme.success;
      case 1:
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = language == SessionLanguage.urdu;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: urgent ? AppTheme.danger : const Color(0xFFE2E8F0),
            width: urgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _complexityColor.withValues(alpha: urgent ? 0.15 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _complexityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _complexityColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    complexityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _complexityColor,
                    ),
                  ),
                ),
                const Spacer(),
                ...List.generate(3, (i) {
                  final filled = i <= tierIndex;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: filled
                          ? (i == 2 ? AppTheme.danger : AppTheme.warning)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (urgent ? AppTheme.danger : AppTheme.primary)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                paragraph.instruction,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: urgent ? AppTheme.danger : AppTheme.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              paragraph.title,
              style: TextStyle(
                fontSize: compact ? 17 : 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              paragraph.body,
              style: TextStyle(
                height: 1.55,
                fontSize: tierIndex == 0 ? 16 : (tierIndex == 1 ? 15.5 : 15),
                fontWeight: tierIndex >= 2 ? FontWeight.w500 : FontWeight.normal,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
