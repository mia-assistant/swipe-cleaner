import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/utils/file_utils.dart';
import '../models/swipe_file.dart';
import '../providers/thumbnail_provider.dart';

/// Individual swipe card with file preview
class SwipeCard extends ConsumerWidget {
  final SwipeFile file;
  final bool isFront;
  final double stackIndex;

  const SwipeCard({
    super.key,
    required this.file,
    this.isFront = true,
    this.stackIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final thumbnailCache = ref.watch(thumbnailCacheProvider);
    
    // Scale and offset for stacked cards
    final scale = 1.0 - (stackIndex * 0.05);
    final offset = stackIndex * -8.0;
    final opacity = 1.0 - (stackIndex * 0.15);

    return Transform.translate(
      offset: Offset(0, offset),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppGradients.card(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.lightAccent.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: isFront
                  ? AppShadows.card(context)
                  : [
                      BoxShadow(
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ],
            ),
            child: Column(
              children: [
                // Thumbnail area (70% of card)
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusCard),
                    ),
                    child: _buildThumbnail(context, thumbnailCache),
                  ),
                ),
                
                // File info area (30% of card)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Filename
                        Text(
                          file.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        
                        // Size and date
                        Text(
                          '${file.formattedSize} · ${file.formattedDate}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted(context),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingSm,
                            vertical: AppConstants.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: file.typeColor(context).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppConstants.radiusBadge),
                          ),
                          child: Text(
                            file.typeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: file.typeColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, Map<String, String?> thumbnailCache) {
    // Show actual image preview for image files
    if (file.type == FileType.image) {
      return Container(
        color: file.typeColor(context).withOpacity(0.08),
        width: double.infinity,
        child: Image.file(
          File(file.uri),
          fit: BoxFit.cover,
          cacheWidth: 600, // limit decode size for performance
          errorBuilder: (context, error, stackTrace) => _buildIconFallback(context),
        ),
      );
    }

    // Show cached video thumbnail
    final cachedPath = thumbnailCache[file.uri];
    if (cachedPath != null) {
      return Container(
        color: file.typeColor(context).withOpacity(0.08),
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(cachedPath),
              fit: BoxFit.cover,
              cacheWidth: 600,
              errorBuilder: (context, error, stackTrace) => _buildIconFallback(context),
            ),
            // Play icon overlay for videos
            if (file.type == FileType.video)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Show thumbnail from model path if available
    if (file.thumbnailPath != null) {
      return Container(
        color: file.typeColor(context).withOpacity(0.08),
        width: double.infinity,
        child: Image.file(
          File(file.thumbnailPath!),
          fit: BoxFit.cover,
          cacheWidth: 600,
          errorBuilder: (context, error, stackTrace) => _buildIconFallback(context),
        ),
      );
    }

    // Video/PDF still loading thumbnail — show icon with spinner
    if ((file.type == FileType.video || file.type == FileType.pdf) &&
        thumbnailCache.containsKey(file.uri)) {
      return _buildIconFallback(context, showLoading: true);
    }

    return _buildIconFallback(context);
  }

  Widget _buildIconFallback(BuildContext context, {bool showLoading = false}) {
    return Container(
      color: file.typeColor(context).withOpacity(0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file.typeIcon,
              size: 96,
              color: file.typeColor(context).withOpacity(0.7),
            ),
            if (showLoading) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: file.typeColor(context).withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
