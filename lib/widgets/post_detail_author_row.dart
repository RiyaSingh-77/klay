import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// PostDetailAuthorRow: a lighter-weight author line for the detail
// screen's header (avatar + name + tappable "View profile" affordance).
// Deliberately separate from widgets/author_header.dart, which is left
// as-is for the fuller author PROFILE screen in Phase 8 (bio, albums,
// etc.) — this one's job is just "whose post is this," nothing more.
class PostDetailAuthorRow extends StatelessWidget {
  final String authorName;
  final VoidCallback? onViewProfile;

  const PostDetailAuthorRow({
    super.key,
    required this.authorName,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onViewProfile,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary,
              child: Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                authorName,
                style: textTheme.titleLarge,
              ),
            ),
            if (onViewProfile != null)
              const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}