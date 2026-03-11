import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:logger_flutter_client/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders auth controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('{..Logger..}'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
