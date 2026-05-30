import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmfresh/screens/auth/login_screen.dart';
import 'package:farmfresh/services/auth_service.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    // We wrap LoginScreen in a Provider and a MaterialApp 
    // because it needs them to function.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthService(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that the App Title 'FarmFresh' is present.
    expect(find.text('FarmFresh'), findsWidgets);

    // Verify that the Login button is present.
    expect(find.text('Login'), findsOneWidget);
    
    // Verify that the Phone Number field is present by looking for its label.
    expect(find.text('Phone Number'), findsOneWidget);

    // Verify that we have a 'Register' button or text.
    expect(find.text('Register'), findsOneWidget);
  });
}
