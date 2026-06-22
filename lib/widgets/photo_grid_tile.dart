import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../theme/app_theme.dart';

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
            color: AppTheme.textFaint.withValues(alpha: 0.3),
            child: const Icon(Icons.broken_image_outlined, color: AppTheme.textFaint),
          ),
        ),
      ),
    );
  }
}