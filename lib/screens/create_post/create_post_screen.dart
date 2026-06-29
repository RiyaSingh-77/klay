import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/draft.dart';
import '../../providers/post_provider.dart';
import '../../providers/library_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_opener.dart';
import '../../services/media_picker_services.dart';
import '../../services/permission_service.dart';
import '../camera/camera_capture_screen.dart';

// CreatePostScreen now has TWO modes behind a toggle:
//   1. "Text Post" — the ORIGINAL flow, completely unchanged: title +
//      body go to JSONPlaceholder via PostProvider.createPost(), with an
//      optional local image/attachment saved as a Draft (since
//      JSONPlaceholder's mock /posts has no field for either — see the
//      comment on ApiService.createPost()).
//   2. "Share Media" — NEW: camera/gallery/audio picker, preview,
//      caption, upload to Cloudinary + Firestore via
//      PostProvider.uploadMediaPost().
//
// Both modes share this one screen/route (AppRoutes.createPost) rather
// than being split into two separate screens, so the FAB on Feed doesn't
// need to change at all.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

enum _PostMode { text, media }

class _CreatePostScreenState extends State<CreatePostScreen> {
  _PostMode _mode = _PostMode.text;

  // ── Text Post state (unchanged from original) ─────────────────────
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  PlatformFile? _pickedAttachment;
  String? _pickedAttachmentWebUrl;

  bool _isSubmitting = false;
  bool _isPickingAttachment = false;

  // ── Share Media state (new) ────────────────────────────────────────
  final _captionController = TextEditingController();
  final MediaPickerService _mediaPickerService = MediaPickerService();
  final PermissionService _permissionService = PermissionService();

  Uint8List? _mediaBytes;
  String? _mediaFileName;
  String? _mediaType; // 'image' | 'video' | 'audio'

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEXT POST — every method below is identical to the original file.
  // ═══════════════════════════════════════════════════════════════════

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

  String _mimeTypeFor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickAttachment() async {
    setState(() => _isPickingAttachment = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'zip', 'jpg', 'png'],
        withData: kIsWeb,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Attachment picker timed out — try a different file.'),
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? webUrl;
        if (kIsWeb && file.bytes != null) {
          webUrl = createBlobUrl(file.bytes!, _mimeTypeFor(file.extension));
        }
        setState(() {
          _pickedAttachment = file;
          _pickedAttachmentWebUrl = webUrl;
        });
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
    setState(() {
      _pickedAttachment = null;
      _pickedAttachmentWebUrl = null;
    });
  }

  Future<void> _submitTextPost() async {
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

      if (_pickedImage != null || _pickedAttachment != null) {
        await libraryProvider.saveDraft(Draft(
          id: newPost.id.toString(),
          title: title,
          body: body,
          imagePath: _pickedImage?.path,
          attachmentPath: kIsWeb ? _pickedAttachmentWebUrl : _pickedAttachment?.path,
          attachmentName: _pickedAttachment?.name,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;
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

  // ═══════════════════════════════════════════════════════════════════
  // SHARE MEDIA — new flow.
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pickGalleryImage() async {
    final granted = await _permissionService.requestGalleryAccess(context);
    if (!granted) return;
    final file = await _mediaPickerService.pickGalleryImage();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _mediaBytes = bytes;
      _mediaFileName = file.name;
      _mediaType = 'image';
    });
  }

  Future<void> _pickGalleryVideo() async {
    final granted = await _permissionService.requestGalleryAccess(context);
    if (!granted) return;
    final file = await _mediaPickerService.pickGalleryVideo();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _mediaBytes = bytes;
      _mediaFileName = file.name;
      _mediaType = 'video';
    });
  }

  Future<void> _pickAudio() async {
    final granted = await _permissionService.requestStorageAccess(context);
    if (!granted) return;
    final file = await _mediaPickerService.pickAudioFile();
    if (file == null || file.bytes == null) return;
    setState(() {
      _mediaBytes = file.bytes;
      _mediaFileName = file.name;
      _mediaType = 'audio';
    });
  }

  Future<void> _openCamera(String captureMode) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.cameraCapture,
      arguments: captureMode,
    ) as CapturedMedia?;
    if (result == null) return;
    setState(() {
      _mediaBytes = result.bytes;
      _mediaFileName = result.fileName;
      _mediaType = result.mediaType;
    });
  }

  void _removeMedia() {
    setState(() {
      _mediaBytes = null;
      _mediaFileName = null;
      _mediaType = null;
    });
  }

  Future<void> _submitMediaPost() async {
    if (_mediaBytes == null || _mediaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a photo, video, or audio file first.')),
      );
      return;
    }

    final postProvider = context.read<PostProvider>();
    final success = await postProvider.uploadMediaPost(
      bytes: _mediaBytes!,
      fileName: _mediaFileName ?? 'upload',
      mediaType: _mediaType!,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(postProvider.uploadErrorMessage ?? 'Upload failed.')),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Column(
        children: [
          _buildModeToggle(),
          Expanded(
            child: _mode == _PostMode.text ? _buildTextPostForm() : _buildMediaPostForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _ToggleTab(
              label: 'Text Post',
              selected: _mode == _PostMode.text,
              onTap: () => setState(() => _mode = _PostMode.text),
            )),
            Expanded(child: _ToggleTab(
              label: 'Share Media',
              selected: _mode == _PostMode.media,
              onTap: () => setState(() => _mode = _PostMode.media),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPostForm() {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
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
                        child: Image.memory(_pickedImageBytes!, fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(top: 8, right: 8, child: _RemoveButton(onTap: _removeImage)),
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
              onPressed: _isSubmitting ? null : _submitTextPost,
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
    );
  }

  Widget _buildMediaPostForm() {
    final textTheme = Theme.of(context).textTheme;
    final postProvider = context.watch<PostProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADD MEDIA', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openCamera('photo'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openCamera('video'),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Record Video'),
              ),
              OutlinedButton.icon(
                onPressed: _pickGalleryImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Gallery Image'),
              ),
              OutlinedButton.icon(
                onPressed: _pickGalleryVideo,
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Gallery Video'),
              ),
              OutlinedButton.icon(
                onPressed: _pickAudio,
                icon: const Icon(Icons.audiotrack_outlined),
                label: const Text('Pick Audio'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_mediaBytes != null) ...[
            Text('PREVIEW', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMediaPreview(),
            const SizedBox(height: 24),
          ],

          Text('CAPTION', style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write a caption...'),
          ),

          const SizedBox(height: 24),

          if (postProvider.isUploadingMedia) ...[
            LinearProgressIndicator(value: postProvider.uploadProgress),
            const SizedBox(height: 8),
            Text(
              'Uploading... ${(postProvider.uploadProgress * 100).toInt()}%',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: postProvider.isUploadingMedia ? null : _submitMediaPost,
              child: postProvider.isUploadingMedia
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('UPLOAD'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaType == 'image') {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 220,
              width: double.infinity,
              color: AppTheme.surface,
              child: Image.memory(_mediaBytes!, fit: BoxFit.contain),
            ),
          ),
          Positioned(top: 8, right: 8, child: _RemoveButton(onTap: _removeMedia)),
        ],
      );
    }

    // Video and audio share the same "filename card" preview — playing
    // either back locally before upload would mean a temp-file round
    // trip on every platform including web, for a file that's about to
    // be uploaded anyway. Full playback is already available once the
    // post lands in the Feed (VideoPlayerWidget/AudioPlayerWidget).
    final icon = _mediaType == 'video' ? Icons.videocam : Icons.audiotrack;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mediaFileName ?? 'Selected file',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _RemoveButton(onTap: _removeMedia),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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