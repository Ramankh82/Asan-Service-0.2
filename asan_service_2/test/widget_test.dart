// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asan_service_2/main.dart'; // مسیر درست رو تنظیم کن

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts correctly.
    expect(find.text('Asan Service'), findsOneWidget);

    // Add more widget tests as needed.
  });
}