import 'package:flutter/material.dart';
import 'app_routes.dart';

// route_generator.dart is the ONE place in the app that knows how to turn
// a route name (a String) into an actual screen widget. MaterialApp calls
// this automatically every time Navigator.pushNamed() is used.
//
// Why onGenerateRoute instead of MaterialApp's simpler `routes: {...}` map?
// Because some screens need ARGUMENTS (e.g. PostDetailScreen needs a
// postId), and the simple `routes` map has no way to receive those. With
// onGenerateRoute, settings.arguments carries whatever was passed to
// pushNamed(), and we can extract and validate it here in one place.
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const _PlaceholderScreen(title: 'Splash'));

      case AppRoutes.login:
        return _page(const _PlaceholderScreen(title: 'Login'));

      case AppRoutes.feed:
        return _page(const _PlaceholderScreen(title: 'Feed'));

      case AppRoutes.postDetail:
        // Example of how an argument will be unpacked once PostDetailScreen
        // exists: `final postId = settings.arguments as int;`
        return _page(const _PlaceholderScreen(title: 'Post Detail'));

      case AppRoutes.authorProfile:
        return _page(const _PlaceholderScreen(title: 'Author Profile'));

      case AppRoutes.albumPhotos:
        return _page(const _PlaceholderScreen(title: 'Album Photos'));

      case AppRoutes.createPost:
        return _page(const _PlaceholderScreen(title: 'Create Post'));

      case AppRoutes.library:
        return _page(const _PlaceholderScreen(title: 'Library'));

      default:
        // Defensive fallback — if a route name typo ever slips through,
        // this shows a clear error screen instead of a blank crash.
        return _page(_PlaceholderScreen(title: 'Route not found: ${settings.name}'));
    }
  }

  static MaterialPageRoute _page(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}

// Temporary screen so the app is runnable from Phase 1 onward.
// Each placeholder gets replaced with its real screen in later phases.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen — coming in a later phase')),
    );
  }
}