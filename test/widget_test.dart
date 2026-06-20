// Basic smoke test for Klay: confirms the app builds and the splash
// screen's first frame renders without throwing.
//
// Deliberately NOT testing navigation past splash (Login -> Feed) here,
// since SplashScreen's _init() does a real async delay + Navigator call
// after the first frame — a fuller test would need tester.pumpAndSettle()
// and mocking SharedPreferences via LibraryProvider. Kept minimal for now.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klay/main.dart';

void main() {
  testWidgets('KlayApp builds and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KlayApp());

    // First frame should be the splash screen with the app's wordmark.
    expect(find.text('klay.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}