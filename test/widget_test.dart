// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:todo_list/main.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for database initialization
    await tester.pumpAndSettle();

    // Verify that the app title is correct
    expect(find.text('My Tasks'), findsOneWidget);

    // Verify that we start with empty state
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Tap + to add your first task'), findsOneWidget);

    // Verify that the floating action button is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the floating action button to add a task
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that the add task dialog appears
    expect(find.text('Add Task'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Cancel the dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify we're back to the empty state
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('Add task functionality test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for database initialization
    await tester.pumpAndSettle();

    // Tap the floating action button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter a task title
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter task title'),
      'Test Task',
    );

    // Tap the Add button
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify that the task appears in the list
    expect(find.text('Test Task'), findsOneWidget);

    // Verify that the empty state is no longer shown
    expect(find.text('No tasks yet'), findsNothing);
  });
}
