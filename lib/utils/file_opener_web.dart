import 'dart:html' as html;
import 'dart:typed_data';

// Turns picked file bytes into a blob: URL. Used for the image preview
// path (rendering inline via Image.network) where we WANT the browser
// to interpret the bytes as a viewable image.
String createBlobUrl(Uint8List bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

// Originally this just called html.window.open(url, '_blank') to open
// the blob URL in a new tab and let Chrome's built-in PDF viewer render
// it. That depends on Chrome successfully PARSING the PDF bytes — and
// when the bytes returned by file_picker on web are even slightly
// corrupted/truncated (a known file_picker-web issue), Chrome's viewer
// fails with "Failed to load PDF document," even though the blob URL
// itself is perfectly valid.
//
// Forcing a download instead sidesteps that entirely: a download just
// writes bytes to disk, it never asks the browser to decode/render them.
// So this opens (and immediately clicks) a hidden anchor tag with a
// `download` attribute — the same primitive every "Save As" link on the
// web uses — rather than navigating to the blob URL directly.
void openWebUrl(String url, [String? downloadName]) {
  final anchor = html.AnchorElement(href: url)
    ..download = downloadName ?? 'attachment'
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
