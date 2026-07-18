// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:music_practice_tracker/app.dart';
import 'package:music_practice_tracker/core/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens login screen when there is no saved token', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(MusicPracticeApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Music Practice Tracker'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });
}
