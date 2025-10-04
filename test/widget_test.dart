import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allergy_app/main.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AllerAIApp());

    // Verify that the welcome screen is displayed
    expect(find.text('AllerAI'), findsOneWidget);
    expect(find.text('Smart Menu Analysis for Food Allergies'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });

  testWidgets('App launches with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const AllerAIApp());

    // Wait for the splash screen to show
    expect(find.text('AllerAI'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}