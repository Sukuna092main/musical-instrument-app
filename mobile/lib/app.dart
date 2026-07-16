import 'package:flutter/material.dart';

import 'features/auth/presentation/splash_screen.dart';

class MusicPracticeApp extends StatelessWidget {
  const MusicPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Practice Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
