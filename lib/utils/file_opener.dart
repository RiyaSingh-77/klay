// Conditional export: on Flutter Web this resolves to file_opener_web.dart
// (which uses dart:html). On every other platform (mobile/desktop) it
// resolves to file_opener_stub.dart instead, since dart:html doesn't
// compile outside web — same reason CreatePostScreen avoids dart:io on
// web. This is the standard Dart pattern for "this code only makes sense
// on one platform": branch at import time, not at runtime, so the wrong
// platform's code never even gets compiled in.
export 'file_opener_stub.dart' if (dart.library.html) 'file_opener_web.dart';
