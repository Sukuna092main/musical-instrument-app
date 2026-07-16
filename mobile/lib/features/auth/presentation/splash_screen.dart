import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../../home/presentation/home_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthApi _api = AuthApi();

  @override
  void initState() {
    super.initState();
    // Điều hướng sau khi frame đầu hoàn tất để tránh push cùng frame với build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final token = await _api.getToken();

    // Không có token → về login.
    if (token == null || token.isEmpty) {
      _goToAuth();
      return;
    }

    try {
      final user = await _api.getMe();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            auth: AuthResult(user: user, accessToken: token),
          ),
        ),
      );
    } catch (_) {
      // Token hết hạn hoặc không hợp lệ → xoá và về login.
      await _api.logout();
      _goToAuth();
    }
  }

  void _goToAuth() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF1F7A5A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Music Practice',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF1F7A5A)),
          ],
        ),
      ),
    );
  }
}
