import 'package:flutter/material.dart';
import '../models/photo.dart';

// PhotoGridTile: one square thumbnail in AlbumPhotosScreen's grid.
// Image.network needs its own loading + error handling per-image (unlike
// a single full-screen fetch, a GridView of 50 photos will have several
// in different load states at once) — loadingBuilder and errorBuilder
// cover that per-tile, independently of every other tile around it.
class PhotoGridTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const PhotoGridTile({
    super.key,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          photo.thumbnailUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.black12,
            child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
          ),
        ),
      ),
    );
  }
}