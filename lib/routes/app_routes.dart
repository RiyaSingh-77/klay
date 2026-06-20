// Every route in the app gets a name here instead of being a magic string
// scattered through screens. This is what "named routes" means in
// practice: Navigator.pushNamed(context, AppRoutes.postDetail) instead of
// Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen())).
//
// The advantage: route names are typo-proof (autocomplete + compile error
// if you misspell one), and route_generator.dart becomes the ONE place
// that knows which screen each name maps to.
// Compile-time error checking, stores all route names in one place.

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String feed = '/feed';
  static const String postDetail = '/post-detail';
  static const String authorProfile = '/author-profile';
  static const String albumPhotos = '/album-photos';
  static const String createPost = '/create-post';
  static const String library = '/library'; // favorites + drafts
}