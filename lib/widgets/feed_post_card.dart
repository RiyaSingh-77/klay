import 'package:flutter/material.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

// FeedPostCard renders ONE post in the feed's ListView. It's a dumb,
// stateless widget on purpose — it just displays the Post + authorName
// it's handed and reports taps via onTap. All the data-fetching (which
// post, which author) lives in FeedScreen / PostProvider / UserProvider,
// not here. This keeps the card reusable and easy to test in isolation.
class FeedPostCard extends StatelessWidget {
  final Post post;
  final String authorName;
  final VoidCallback onTap;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.authorName,
    required this.onTap,
  });

  // Body text from JSONPlaceholder can run long and often contains
  // newlines mid-sentence. A feed card should tease the post, not show
  // the whole thing — Text's maxLines + overflow handles the visual
  // truncation, this just keeps the raw string itself clean.
  String get _bodyPreview => post.body.replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Author row ──────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authorName,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Title ───────────────────────────────────────
              Text(
                post.title,
                style: textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // ── Body preview ────────────────────────────────
              Text(
                _bodyPreview,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}