import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// MediaPickerService wraps image_picker (gallery image/video) and
// file_picker (audio) behind one interface — CreatePostScreen calls
// these instead of importing either package directly.
class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<XFile?> pickGalleryImage() {
    return _imagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> pickGalleryVideo() {
    return _imagePicker.pickVideo(source: ImageSource.gallery);
  }

  // withData: true is necessary here (unlike the existing attachment
  // picker in CreatePostScreen, which only sets it on web) because
  // EVERY platform needs raw bytes for this picker — they go straight
  // into CloudinaryService.uploadMedia(), which has no concept of a
  // file path, only bytes. Audio files are small enough that loading
  // them fully into memory up front isn't a real cost.
  Future<PlatformFile?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }
}