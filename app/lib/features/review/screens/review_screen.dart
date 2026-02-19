import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/polished_widgets.dart';
import '../../swipe/models/swipe_file.dart';
import '../../swipe/providers/swipe_files_provider.dart';
import '../../swipe/providers/thumbnail_provider.dart';
import '../providers/purchase_provider.dart';

/// Review screen showing files marked for deletion
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swipeState = ref.watch(swipeFilesProvider);
    final purchaseState = ref.watch(purchaseProvider);
    final theme = Theme.of(context);
    final toDelete = swipeState.toDelete;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: toDelete.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildContent(context, ref, theme, toDelete, purchaseState),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: AppColors.muted(context),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Nothing to delete',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Go back and swipe left on\nfiles you want to remove',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<SwipeFile> toDelete,
    PurchaseState purchaseState,
  ) {
    final totalSize = toDelete.fold<int>(0, (sum, f) => sum + f.sizeBytes);

    return Column(
      children: [
        // Header stats
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.delete(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            ),
            child: Column(
              children: [
                Text(
                  'Ready to clear',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted(context),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  '${toDelete.length} files',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  FileUtils.formatBytes(totalSize),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.delete(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tap instruction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
          child: Text(
            'Tap any to undo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted(context),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),

        // File grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppConstants.spacingSm,
              mainAxisSpacing: AppConstants.spacingSm,
            ),
            itemCount: toDelete.length,
            itemBuilder: (context, index) {
              final file = toDelete[index];
              return _FileGridItem(
                file: file,
                onTap: () {
                  ref.read(swipeFilesProvider.notifier).removeFromDelete(file);
                },
              );
            },
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.surface(context).withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.muted(context).withOpacity(0.15),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: purchaseState.isUnlocked
                      ? '🗑️  Clear ${toDelete.length} Files'
                      : '🗑️  Clear All  ${purchaseState.price ?? '...'}',
                  onPressed: () {
                    if (purchaseState.isUnlocked) {
                      context.go('/delete');
                    } else {
                      _showPaywall(context, ref);
                    }
                  },
                  isLoading: purchaseState.isLoading,
                ),
                if (!purchaseState.isUnlocked) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  TextButton(
                    onPressed: () {
                      ref.read(purchaseProvider.notifier).restorePurchases();
                    },
                    child: Text(
                      'Already purchased? Restore',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaywall(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaywallSheet(
        onPurchase: () {
          ref.read(purchaseProvider.notifier).purchase();
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _FileGridItem extends ConsumerWidget {
  final SwipeFile file;
  final VoidCallback onTap;

  const _FileGridItem({
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailCache = ref.watch(thumbnailCacheProvider);
    final cachedPath = thumbnailCache[file.uri];

    return Material(
      color: file.typeColor(context).withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Column(
          children: [
            Expanded(
              child: _buildPreview(context, cachedPath),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXxs,
                vertical: 2,
              ),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, String? cachedThumbnail) {
    // Image/Video/PDF with cached local path or thumbnail
    if (cachedThumbnail != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(cachedThumbnail),
            fit: BoxFit.cover,
            width: double.infinity,
            cacheWidth: 200,
            errorBuilder: (_, __, ___) => _iconFallback(context),
          ),
          if (file.type == FileType.video)
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 22,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
        ],
      );
    }

    return _iconFallback(context);
  }

  Widget _iconFallback(BuildContext context) {
    return Center(
      child: Icon(
        file.typeIcon,
        color: file.typeColor(context),
        size: 28,
      ),
    );
  }
}

class _PaywallSheet extends ConsumerWidget {
  final VoidCallback onPurchase;
  final VoidCallback onCancel;

  const _PaywallSheet({
    required this.onPurchase,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final price = ref.watch(purchaseProvider).price;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusCard),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Title
              Text(
                '✨ Unlock SwipeClear',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'One-time purchase. Forever.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Price card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                  border: Border.all(
                    color: AppColors.accent(context),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      price ?? '...',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Benefits
              _BenefitRow(icon: Icons.check, text: 'Unlimited folder cleaning'),
              const SizedBox(height: AppConstants.spacingSm),
              _BenefitRow(icon: Icons.check, text: 'All future updates'),
              const SizedBox(height: AppConstants.spacingSm),
              _BenefitRow(icon: Icons.check, text: 'No subscriptions ever'),
              const SizedBox(height: AppConstants.spacingXl),

              // Buttons
              AppButton(
                text: 'Unlock SwipeClear',
                onPressed: onPurchase,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.muted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.keep(context),
          size: 20,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
