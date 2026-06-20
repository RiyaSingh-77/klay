import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const KlayApp());
}

class KlayApp extends StatelessWidget {
  const KlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: Providers (PostProvider, UserProvider, etc.) will wrap this
    // MaterialApp starting in Phase 5, once they exist. For now this is
    // intentionally just routing + theme, so the app is runnable today.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Klay',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}