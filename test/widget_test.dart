import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_track/core/theme.dart';
import 'package:trade_track/features/placeholder/placeholder_screen.dart';

void main() {
  testWidgets('PlaceholderScreen renders localized title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.dark,
        home: const Scaffold(
          body: PlaceholderScreen(titleKey: 'nav.home'),
        ),
      ),
    );

    expect(find.text('Accueil'), findsOneWidget);
  });
}

