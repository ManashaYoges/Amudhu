import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/main.dart';

void main() {
  testWidgets('WelcomeGate toggles between Log In and Create Account mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AmuduApp());

    // Initially in Log In mode
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Full Name'), findsNothing);

    // Tap 'Create an account'
    final createAccountFinder = find.text('Create an account');
    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);
    await tester.pumpAndSettle();

    // Now in Create Account mode
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Already have an account? Log In'), findsOneWidget);

    // Tap 'Already have an account? Log In'
    final loginToggleFinder = find.text('Already have an account? Log In');
    await tester.ensureVisible(loginToggleFinder);
    await tester.tap(loginToggleFinder);
    await tester.pumpAndSettle();

    // Toggled back to Log In mode
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('WelcomeGate guest mode navigates to MainShell',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AmuduApp());

    // Tap 'Continue as guest'
    final guestFinder = find.text('Continue as guest');
    await tester.ensureVisible(guestFinder);
    await tester.tap(guestFinder);
    await tester.pumpAndSettle();

    // Verify MainShell is rendered with bottom navigation
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Meal Plan'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
