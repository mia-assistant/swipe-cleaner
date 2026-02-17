import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/polished_widgets.dart';
import '../../swipe/providers/swipe_files_provider.dart';
import '../../swipe/services/session_storage_service.dart';
import '../providers/folder_provider.dart';
import '../../review/providers/purchase_provider.dart';

/// Screen for selecting a folder to clean
class FolderPickerScreen extends ConsumerStatefulWidget {
  const FolderPickerScreen({super.key});

  @override
  ConsumerState<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends ConsumerState<FolderPickerScreen> {
  SwipeSession? _savedSession;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkForSavedSession();
  }

  Future<void> _checkForSavedSession() async {
    final session = await SessionStorageService.loadSession();
    if (mounted) {
      setState(() {
        _savedSession = session;
        _checkingSession = false;
      });
    }
  }

  Future<void> _resumeSession() async {
    if (_savedSession == null) return;

    // Set folder state
    ref.read(folderProvider.notifier).setFolder(
          _savedSession!.folderUri,
          _savedSession!.folderName,
        );

    // Restore session BEFORE navigating so data is ready
    await ref.read(swipeFilesProvider.notifier).restoreSession(_savedSession!);

    // Navigate after restore is complete
    if (mounted) {
      context.go('/swipe');
    }
  }

  Future<void> _discardSession() async {
    await SessionStorageService.clearSession();
    if (mounted) {
      setState(() {
        _savedSession = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderState = ref.watch(folderProvider);
    final theme = Theme.of(context);

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            children: [
              // Saved session card
              if (!_checkingSession && _savedSession != null) ...[
                _SavedSessionCard(
                  session: _savedSession!,
                  onResume: _resumeSession,
                  onDiscard: _discardSession,
                ),
                const SizedBox(height: AppConstants.spacingXl),
              ],

              // Folder Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 56,
                  color: AppColors.accent(context),
                ),
              ),

              const SizedBox(height: AppConstants.spacingXl),

              // Instruction Text
              Text(
                'Choose a folder to clean',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: AppConstants.spacingSm),

              Text(
                'We recommend starting with\nyour Downloads folder',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // Upfront pricing badge + unlock button
              Builder(
                builder: (context) {
                  final purchaseState = ref.watch(purchaseProvider);
                  final price = purchaseState.price;

                  if (purchaseState.isUnlocked) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: AppConstants.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent(context).withOpacity(0.1),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(AppConstants.radiusFull),
                          ),
                          border: Border.all(
                            color: AppColors.accent(context).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Free to swipe · ${price ?? '...'} to delete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.accent(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(purchaseProvider.notifier).purchase();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingMd,
                            vertical: AppConstants.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent(context),
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(AppConstants.radiusFull),
                            ),
                          ),
                          child: purchaseState.isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Unlock',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppConstants.spacingXl),

              // Quick-select Downloads button
              AppButton(
                text: folderState.isLoading
                    ? 'Opening...'
                    : 'Select Downloads Folder',
                icon: Icons.download_rounded,
                isLoading: folderState.isLoading,
                onPressed: folderState.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(folderProvider.notifier)
                            .selectDownloads();
                        if (success && context.mounted) {                          await SessionStorageService.clearSession();
                          ref.read(swipeFilesProvider.notifier).reset();                          context.go('/swipe');
                        }
                      },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Error message
              if (folderState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.delete(context).withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCard),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.delete(context),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          folderState.error!,
                          style: TextStyle(color: AppColors.delete(context)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
              ],

              // Open Folder Picker Button (for other folders)
              AppButton.secondary(
                text: folderState.isLoading
                    ? 'Opening...'
                    : 'Choose Another Folder',
                icon: Icons.folder_rounded,
                isLoading: folderState.isLoading,
                onPressed: folderState.isLoading
                    ? null
                    : () async {
                        final success =
                            await ref.read(folderProvider.notifier).pickFolder();
                        if (success && context.mounted) {
                          // Clear any saved session when starting fresh
                          await SessionStorageService.clearSession();
                          ref.read(swipeFilesProvider.notifier).reset();
                          context.go('/swipe');
                        }
                      },
              ),

              const SizedBox(height: AppConstants.spacingXl),

              // Info Text
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                  border: Border.all(
                    color: AppColors.muted(context).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.muted(context),
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'We only delete files you swipe left on, and you\'ll review them before anything is removed',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing saved session with resume/discard options
class _SavedSessionCard extends StatelessWidget {
  final SwipeSession session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _SavedSessionCard({
    required this.session,
    required this.onResume,
    required this.onDiscard,
  });

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: AppColors.accent(context).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: AppColors.accent(context),
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                'Continue where you left off?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            '${session.folderName} · ${session.totalReviewed} files reviewed · ${_formatTimeAgo(session.savedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted(context),
                    side: BorderSide(
                      color: AppColors.muted(context).withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusButton,
                      ),
                    ),
                  ),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: FilledButton(
                  onPressed: onResume,
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
                  child: const Text('Resume'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
