import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/polished_widgets.dart';
import '../../folder_picker/providers/folder_provider.dart';
import '../providers/swipe_files_provider.dart';
import '../providers/thumbnail_provider.dart';
import '../services/session_storage_service.dart';
import '../widgets/swipe_stack.dart';

/// Main swipe screen for reviewing files
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final GlobalKey<SwipeStackState> _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load files when screen opens (skip if already loaded from restore)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(swipeFilesProvider);
      // Only load if we don't already have files (e.g., from session restore)
      if (currentState.files.isEmpty && !currentState.isLoading) {
        await ref.read(swipeFilesProvider.notifier).loadFiles();
      }
      _preloadThumbnails();
    });
  }

  /// Preload thumbnails and precache images for upcoming files.
  void _preloadThumbnails() {
    final swipeState = ref.read(swipeFilesProvider);
    if (swipeState.files.isEmpty) return;

    final cacheNotifier = ref.read(thumbnailCacheProvider.notifier);
    cacheNotifier.preload(swipeState.files, swipeState.currentIndex);
    cacheNotifier.precacheImages(
      swipeState.files,
      swipeState.currentIndex,
      context,
    );
  }

  /// Show exit confirmation when user has swiped files
  Future<bool> _onWillPop() async {
    final swipeState = ref.read(swipeFilesProvider);
    
    // No progress to lose - allow exit
    if (swipeState.currentIndex == 0 && swipeState.toDelete.isEmpty) {
      return true;
    }

    final shouldExit = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExitConfirmationSheet(
        filesReviewed: swipeState.currentIndex,
        filesToDelete: swipeState.toDelete.length,
        onSaveAndExit: () {
          ref.read(swipeFilesProvider.notifier).saveSession();
        },
      ),
    );

    return shouldExit ?? false;
  }

  void _swipeLeft() {
    _stackKey.currentState?.swipe(SwipeDirection.left);
  }

  void _swipeRight() {
    _stackKey.currentState?.swipe(SwipeDirection.right);
  }

  void _onSwipe(SwipeDirection direction) {
    if (direction == SwipeDirection.left) {
      ref.read(swipeFilesProvider.notifier).swipeLeft();
    } else {
      ref.read(swipeFilesProvider.notifier).swipeRight();
    }
    // Preload thumbnails for next batch of files
    _preloadThumbnails();
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeFilesProvider);
    final folderState = ref.watch(folderProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/folder-picker');
        }
      },
      child: GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folderState.folderName ?? 'Files'),
            if (!swipeState.isLoading && swipeState.files.isNotEmpty)
              Text(
                '${swipeState.remainingCount} files left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),
          ],
        ),
        actions: [
          if (!swipeState.isLoading && swipeState.toDelete.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppConstants.spacingMd),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => context.push('/review'),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label: Text(
                    '${swipeState.toDelete.length} to clear',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.delete(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, swipeState, theme),
    ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SwipeFilesState swipeState,
    ThemeData theme,
  ) {
    // Loading state
    if (swipeState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (swipeState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.delete(context),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                swipeState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                text: 'Try Again',
                onPressed: () {
                  ref.read(swipeFilesProvider.notifier).loadFiles();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (swipeState.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✨',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Already spotless!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'This folder has no files to\nclean. Nice work.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              AppButton(
                text: 'Pick Another Folder',
                onPressed: () {
                  ref.read(swipeFilesProvider.notifier).reset();
                  ref.read(folderProvider.notifier).clearFolder();
                  context.go('/folder-picker');
                },
              ),
            ],
          ),
        ),
      );
    }

    // Complete state (all swiped)
    if (swipeState.isComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.keep(context),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'All done!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'You\'ve reviewed all ${swipeState.files.length} files',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),
              if (swipeState.toDelete.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingXl),
                AppButton(
                  text: 'Review & Delete',
                  icon: Icons.delete_outline,
                  onPressed: () => context.push('/review'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Swipe card stack
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        children: [
          // Card stack
          Expanded(
            child: SwipeStack(
              key: _stackKey,
              files: swipeState.files,
              currentIndex: swipeState.currentIndex,
              onSwipe: _onSwipe,
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Swipe indicators + buttons
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              // Delete button
              _SwipeButton(
                icon: Icons.close_rounded,
                label: 'DELETE',
                color: AppColors.delete(context),
                onPressed: _swipeLeft,
              ),
              _SwipeButton(
                icon: Icons.check_rounded,
                label: 'KEEP',
                color: AppColors.keep(context),
                onPressed: _swipeRight,
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

}

class _SwipeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SwipeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Bottom sheet for confirming exit with progress
class _ExitConfirmationSheet extends StatelessWidget {
  final int filesReviewed;
  final int filesToDelete;
  final VoidCallback onSaveAndExit;

  const _ExitConfirmationSheet({
    required this.filesReviewed,
    required this.filesToDelete,
    required this.onSaveAndExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppConstants.spacingLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppConstants.spacingLg),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.coffee_rounded,
              color: AppColors.accent(context),
              size: 28,
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Title
          Text(
            'Taking a break?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // Progress info
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
            ),
            child: Text(
              filesToDelete > 0
                  ? 'You\'ve reviewed $filesReviewed files and marked $filesToDelete for deletion.'
                  : 'You\'ve reviewed $filesReviewed files.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted(context),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
            ),
            child: Column(
              children: [
                // Keep going
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.swipe_rounded, size: 20),
                    label: const Text('Keep Going'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusButton,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingSm),

                // Save and continue later
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onSaveAndExit();
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.bookmark_outline_rounded, size: 20),
                    label: const Text('Continue Later'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(context),
                      side: BorderSide(color: AppColors.accent(context)),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusButton,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingSm),

                // Exit anyway
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      await SessionStorageService.clearSession();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted(context),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingMd,
                      ),
                    ),
                    child: const Text('Discard Progress'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),
        ],
      ),
    );
  }
}
