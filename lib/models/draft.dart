//Draft is a local-only model.
//Unlike Post, User, Album, Photo, and Comment, which are created from server responses,
// a Draft is created by the user on the device and must survive app restarts.
//Because SharedPreferences cannot store Dart objects directly.
//It only stores primitive values like String, int, bool, and List.
//Therefore the Draft object must be converted to JSON before saving and reconstructed from JSON when loading.
//Draft is a locally-created model with no API equivalent — it carries full toJson/fromJson for round-tripping
//through SharedPreferences, since favorites/drafts have no backend.

class Draft {
  final String id;            // generated locally, not from a server
  final String title;
  final String body;
  final String? imagePath;       // local file path from image_picker, nullable — not every draft has an image
  final String? attachmentPath;  // local file path from file_picker
  final String? attachmentName;  // original filename, shown in the UI instead of a raw path
  final DateTime createdAt;

  Draft({
    required this.id,
    required this.title,
    required this.body,
    this.imagePath,
    this.attachmentPath,
    this.attachmentName,
    required this.createdAt,
  });

  // Convenience constructor: builds a new Draft with a fresh id/timestamp,
  // so callers (the create-post screen) don't have to generate those
  // themselves every time.
  factory Draft.create({
    required String title,
    required String body,
    String? imagePath,
    String? attachmentPath,
    String? attachmentName,
  }) {
    return Draft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      imagePath: imagePath,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imagePath': imagePath,
      'attachmentPath': attachmentPath,
      'attachmentName': attachmentName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imagePath: json['imagePath'],
      attachmentPath: json['attachmentPath'],
      attachmentName: json['attachmentName'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}