import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/draft.dart';
import '../../providers/post_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_theme.dart';

// CreatePostScreen sends title + body to JSONPlaceholder via
// PostProvider.createPost(), but the picked image and file attachment
// have NO field on JSONPlaceholder's /posts resource — see the comment
// on ApiService.createPost() for why. So after a successful create, this
// screen saves a Draft (via LibraryProvider) using the SAME id as the new
// server post, pairing the local media to the post it belongs to. That's
// the app's local-persistence boundary, not a workaround.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes; // read once at pick-time for the live preview

  PlatformFile? _pickedAttachment;

  bool _isSubmitting = false;
  bool _isPickingAttachment = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // Reading bytes via XFile.readAsBytes() (instead of Image.file(File(...)))
  // is what keeps this screen working identically on Flutter Web and on
  // mobile — dart:io's File class doesn't compile on web at all, so any
  // code path that touches it directly would need a web/io branch. Bytes
  // sidestep that entirely.
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _pickedImageBytes = null;
    });
  }

  // withData defaults to false here on purpose — earlier this forced
  // withData: true, which makes file_picker read the ENTIRE file's bytes
  // into memory before returning, even though we only ever display the
  // filename. For a large PDF that read is slow and gives zero visual
  // feedback while it runs, which looks exactly like the screen has
  // frozen. We don't use the bytes for anything yet, so we don't ask for
  // them — if a "preview attachment" feature gets added later, request
  // bytes there, scoped to just that feature.
  // FilePicker.pickFiles() has known, reported issues on Flutter Web
  // where it hangs specifically for certain MIME types (PDF being a
  // common one) on some Chrome versions — this is a third-party plugin
  // behavior, not something fixable from inside this app. The
  // responsible move is the same one we used for ApiService: never let
  // a call sit unbounded. .timeout() here guarantees the UI recovers
  // with a clear message instead of spinning forever, regardless of
  // what's happening inside the plugin.
  Future<void> _pickAttachment() async {
    setState(() => _isPickingAttachment = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'zip', 'jpg', 'png'],
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Attachment picker timed out — try a different file.'),
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pickedAttachment = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not attach file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  void _removeAttachment() {
    setState(() => _pickedAttachment = null);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title and body can\'t be empty')));
      return;
    }

    setState(() => _isSubmitting = true);

    final postProvider = context.read<PostProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    // Everything from here down is wrapped in try/finally on purpose.
    // Previously, if saveDraft() (or anything after createPost succeeded)
    // threw for any reason, the function would exit without ever
    // reaching the setState that turns _isSubmitting back to false —
    // leaving the POST button spinning forever with no way to recover
    // short of a hot restart. finally guarantees that reset always runs.
    try {
      final newPost = await postProvider.createPost(title: title, body: body);

      if (newPost == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(postProvider.errorMessage ?? 'Could not create post.')),
          );
        }
        return;
      }

      // Pair the local media to the post that was just created, keyed by
      // the SAME id JSONPlaceholder handed back — not a fresh timestamp
      // id like Draft.create() would generate, since this isn't an
      // unsent draft, it's metadata riding alongside a post that
      // already exists.
      if (_pickedImage != null || _pickedAttachment != null) {
        await libraryProvider.saveDraft(Draft(
          id: newPost.id.toString(),
          title: title,
          body: body,
          imagePath: _pickedImage?.path,
          // PlatformFile.path is a known trap on Flutter Web — unlike most
          // nullable getters, it doesn't quietly return null when there's
          // no real filesystem path to give you, it THROWS instead (see
          // https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ).
          // That exception was firing inside saveDraft() and killing this
          // function before _isSubmitting ever got reset — the real cause
          // of the stuck spinner. kIsWeb guards it: on web we just never
          // touch .path at all, since we don't use it for anything beyond
          // the (web-only) image preview, which already goes through
          // bytes instead, never path.
          attachmentPath: kIsWeb ? null : _pickedAttachment?.path,
          attachmentName: _pickedAttachment?.name,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;

      // Pop back to Feed rather than pushNamed — CreatePostScreen was
      // pushed ON TOP of Feed (via the FAB), and PostProvider.createPost()
      // already inserted newPost at index 0 of the SAME _posts list Feed
      // is watching. Popping back just reveals it, already at the top —
      // no separate "refresh" or argument-passing needed.
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TITLE', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'What\'s this post about?'),
            ),

            const SizedBox(height: 20),
            Text('BODY', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Write something...'),
            ),

            const SizedBox(height: 24),
            Text('PHOTO (optional)', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 8),
            _pickedImageBytes == null
                ? OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add Photo'),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: AppTheme.surface,
                          child: Image.memory(
                            _pickedImageBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _RemoveButton(onTap: _removeImage),
                      ),
                    ],
                  ),

            const SizedBox(height: 24),
            Text('ATTACHMENT (optional)', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 8),
            _pickedAttachment == null
                ? OutlinedButton.icon(
                    onPressed: _isPickingAttachment ? null : _pickAttachment,
                    icon: _isPickingAttachment
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                    label: Text(_isPickingAttachment ? 'Attaching...' : 'Attach File'),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedAttachment!.name,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        _RemoveButton(onTap: _removeAttachment),
                      ],
                    ),
                  ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('POST'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }
}