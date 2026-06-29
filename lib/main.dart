import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';
import 'providers/post_provider.dart';
import 'providers/user_provider.dart';
import 'providers/album_provider.dart';
import 'providers/library_provider.dart';

// main() is now async because Firebase.initializeApp() is itself async —
// it has to complete BEFORE runApp() fires, otherwise any screen that
// touches Firestore on first frame (the Feed, via PostProvider) would
// race against a Firebase instance that isn't ready yet and throw.
//
// WidgetsFlutterBinding.ensureInitialized() is required any time you do
// async work in main() before runApp() — Flutter's engine bindings
// normally initialize lazily on the first runApp() call, and several
// plugins (Firebase among them) call into platform channels during
// initializeApp(), which needs those bindings already set up.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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