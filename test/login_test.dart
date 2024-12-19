import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'pac'; // Adjust based on your app structure

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login Test with email and password', (WidgetTester tester) async {
    // Launch the app
    await tester.pumpWidget(MyApp());

    // Wait for the LoginPage to load
    await tester.pumpAndSettle();

    // Find the email and password TextFields
    final emailField = find.byKey(Key('loginTextFieldKey'));
    final passwordField = find.byKey(Key('PasswordTextFieldKey'));
    final loginButton = find.byType(ElevatedButton);

    // Input the email
    await tester.enterText(emailField, 'ahhmed@gmail.com');
    await tester.pump();

    // Input the password
    await tester.enterText(passwordField, '1234512345');
    await tester.pump();

    // Press the login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify successful navigation (update the HomePage title if needed)
    expect(find.text('Home'), findsOneWidget);
  });
}
