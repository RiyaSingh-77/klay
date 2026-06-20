import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

// SplashScreen does one real job: load favorites/drafts from disk via
// LibraryProvider BEFORE the user reaches any screen that might display
// them. Without this, the Feed or Library screen could render its first
// frame before SharedPreferences has finished reading, showing an empty
// favorites list for a split second even if some exist.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await context.read<LibraryProvider>().loadLibrary();
    // A short artificial delay so the splash doesn't flash by instantly
    // on a fast connection — purely cosmetic, not loading anything extra.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'klay.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'a slower, warmer place to share',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}