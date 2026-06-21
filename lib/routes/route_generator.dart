import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/post_detail/post_detail_screen.dart';
import '../screens/author/author_profile_screen.dart';
import '../screens/albums/album_photos_screen.dart';
import '../screens/create_post/create_post_screen.dart';

// route_generator.dart is the ONE place in the app that knows how to turn
// a route name (a String) into an actual screen widget. MaterialApp calls
// this automatically every time Navigator.pushNamed() is used.
//
// Why onGenerateRoute instead of MaterialApp's simpler `routes: {...}` map?
// Because several screens need ARGUMENTS (PostDetailScreen needs a
// postId, AuthorProfileScreen needs a userId, AlbumPhotosScreen needs an
// albumId) — the simple `routes` map has no way to receive those.
// settings.arguments carries whatever was passed to pushNamed(), and we
// extract + validate it here in one place rather than in every screen.
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen());

      case AppRoutes.login:
        return _page(const LoginScreen());

      case AppRoutes.feed:
        return _page(const FeedScreen());

      case AppRoutes.postDetail:
        // Usage: Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post.id);
        final postId = settings.arguments as int?;
        if (postId == null) {
          return _page(const _PlaceholderScreen(title: 'Post Detail — missing postId'));
        }
        return _page(PostDetailScreen(postId: postId));

      case AppRoutes.authorProfile:
        // Usage: Navigator.pushNamed(context, AppRoutes.authorProfile, arguments: post.userId);
        final userId = settings.arguments as int?;
        if (userId == null) {
          return _page(const _PlaceholderScreen(title: 'Author Profile — missing userId'));
        }
        return _page(AuthorProfileScreen(userId: userId));

      case AppRoutes.albumPhotos:
        // Usage: Navigator.pushNamed(context, AppRoutes.albumPhotos, arguments: album.id);
        final albumId = settings.arguments as int?;
        if (albumId == null) {
          return _page(const _PlaceholderScreen(title: 'Album Photos — missing albumId'));
        }
        return _page(AlbumPhotosScreen(albumId: albumId));

      case AppRoutes.createPost:
        return _page(const CreatePostScreen());

      case AppRoutes.library:
        return _page(const _PlaceholderScreen(title: 'Library')); // Phase 10

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

// Temporary screen for routes not yet built — each gets replaced with its
// real screen in the phase noted above.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — coming in a later phase')),
    );
  }
}