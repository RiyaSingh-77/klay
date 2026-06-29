import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/post_detail/post_detail_screen.dart';
import '../screens/author/author_profile_screen.dart';
import '../screens/albums/album_photos_screen.dart';
import '../screens/create_post/create_post_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/camera/camera_capture_screen.dart';

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
        final postId = settings.arguments as int?;
        if (postId == null) {
          return _page(const _PlaceholderScreen(title: 'Post Detail — missing postId'));
        }
        return _page(PostDetailScreen(postId: postId));

      case AppRoutes.authorProfile:
        final userId = settings.arguments as int?;
        if (userId == null) {
          return _page(const _PlaceholderScreen(title: 'Author Profile — missing userId'));
        }
        return _page(AuthorProfileScreen(userId: userId));

      case AppRoutes.albumPhotos:
        final albumId = settings.arguments as int?;
        if (albumId == null) {
          return _page(const _PlaceholderScreen(title: 'Album Photos — missing albumId'));
        }
        return _page(AlbumPhotosScreen(albumId: albumId));

      case AppRoutes.createPost:
        return _page(const CreatePostScreen());

      case AppRoutes.library:
        return _page(const LibraryScreen());

      case AppRoutes.cameraCapture:
        final captureMode = settings.arguments as String?;
        if (captureMode == null) {
          return _page(const _PlaceholderScreen(title: 'Camera — missing captureMode'));
        }
        return _page(CameraCaptureScreen(captureMode: captureMode));

      default:
        return _page(_PlaceholderScreen(title: 'Route not found: ${settings.name}'));
    }
  }

  static MaterialPageRoute _page(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}

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