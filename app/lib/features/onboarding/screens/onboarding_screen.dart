import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/polished_widgets.dart';
import '../providers/onboarding_provider.dart';
import '../../review/providers/purchase_provider.dart';

/// Onboarding screen shown on first launch
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Icon
              Container(
                width: AppConstants.onboardingIconSize,
                height: AppConstants.onboardingIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent(context).withOpacity(0.1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/icon/icon_rounded.png',
                  width: AppConstants.onboardingIconSize,
                  height: AppConstants.onboardingIconSize,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: AppConstants.spacingXl),

              // Title
              Text(
                'SwipeCleaner',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // Subtitle
              Text(
                'Clean any folder\nwith satisfying swipes',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
              ),

              const Spacer(),

              // Swipe Instructions
              _SwipeInstructions(),

              const Spacer(),

              // Price Disclosure
              Builder(
                builder: (context) {
                  final price = ref.watch(purchaseProvider).price;
                  return Text(
                    'One-time purchase: ${price ?? '...'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted(context),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // CTA Button
              AppButton(
                text: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  ref.read(onboardingProvider.notifier).markOnboardingSeen();
                  context.go('/folder-picker');
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Swipe Left = Delete
        _SwipeInstruction(
          icon: Icons.arrow_back_rounded,
          label: 'Delete',
          color: AppColors.delete(context),
        ),

        const SizedBox(width: AppConstants.spacing2xl),

        // Swipe Right = Keep
        _SwipeInstruction(
          icon: Icons.arrow_forward_rounded,
          label: 'Keep',
          color: AppColors.keep(context),
        ),
      ],
    );
  }
}

class _SwipeInstruction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SwipeInstruction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
