import 'package:flutter/material.dart';

import 'app.dart';
import 'core/settings/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettings();
  await settings.load();

  runApp(MusicPracticeApp(settings: settings));
}
