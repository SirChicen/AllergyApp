import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allergy_app/main.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AllergyApp());

    // Verify that the welcome screen is displayed
    expect(find.text('Welcome to Allergy App'), findsOneWidget);
    expect(find.text('Scan restaurant menus to identify allergens'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });

  testWidgets('App bar shows correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const AllergyApp());

    // Verify that the app bar title is correct
    expect(find.text('Allergy App'), findsOneWidget);
  });
}