import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';
import 'providers/post_provider.dart';
import 'providers/user_provider.dart';
import 'providers/album_provider.dart';
import 'providers/library_provider.dart';

void main() {
  runApp(const KlayApp());
}

class KlayApp extends StatelessWidget {
  const KlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the whole app once, here, so every screen below
    // it — no matter how deep in the navigation stack — can reach any of
    // these four providers via context.watch<X>() or context.read<X>(),
    // without passing data down through constructors screen by screen.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Klay',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}