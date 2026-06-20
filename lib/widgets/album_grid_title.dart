import 'package:flutter/material.dart';
import '../models/album.dart';
import '../theme/app_theme.dart';

// AlbumGridTitle: one tile in the album grid on AuthorProfileScreen.
// JSONPlaceholder's Album only has an id/userId/title — no cover photo —
// so the tile leans on an icon + title rather than pretending there's a
// thumbnail to show. Tapping a tile is how the user drills into
// AlbumPhotosScreen (Phase 8's second screen).
class AlbumGridTitle extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumGridTitle({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.photo_library_outlined, color: AppTheme.primary, size: 26),
              Text(
                album.title,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}