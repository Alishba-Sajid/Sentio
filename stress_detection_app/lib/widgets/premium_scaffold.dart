import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.premiumBackgroundDecoration(),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
          ),
        ],
      ),
    );
  }
}
