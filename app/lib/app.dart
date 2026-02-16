import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/folder_picker/screens/folder_picker_screen.dart';
import 'features/swipe/screens/swipe_screen.dart';
import 'features/review/screens/review_screen.dart';
import 'features/delete/screens/delete_animation_screen.dart';

/// Listenable adapter that bridges a Riverpod [Ref] provider to a
/// [ChangeNotifier] so GoRouter can re-evaluate its redirect whenever the
/// watched provider emits a new value.
class _OnboardingRefreshListenable extends ChangeNotifier {
  _OnboardingRefreshListenable(Ref ref) {
    ref.listen<OnboardingState>(onboardingProvider, (_, next) {
      _state = next;
      notifyListeners();
    });
    _state = ref.read(onboardingProvider);
  }

  OnboardingState _state = const OnboardingState();
  OnboardingState get state => _state;
}

/// Provider that keeps one GoRouter alive for the lifetime of the app.
final _routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _OnboardingRefreshListenable(ref);

  final router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final onboardingState = refreshListenable.state;

      // Still loading onboarding state
      if (onboardingState.isLoading) {
        return null;
      }

      // If onboarding is seen and we're on the onboarding screen, redirect
      if (onboardingState.hasSeenOnboarding &&
          state.matchedLocation == '/onboarding') {
        return '/folder-picker';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/folder-picker',
        builder: (context, state) => const FolderPickerScreen(),
      ),
      GoRoute(
        path: '/swipe',
        builder: (context, state) => const SwipeScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/delete',
        builder: (context, state) => const DeleteAnimationScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Main app widget with theme and routing configuration
class SwipeClearApp extends StatelessWidget {
  const SwipeClearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final router = ref.watch(_routerProvider);

          return MaterialApp.router(
            title: 'SwipeClear',
            debugShowCheckedModeBanner: false,

            // Theme configuration - follows system
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,

            // Router configuration
            routerConfig: router,
          );
        },
      ),
    );
  }
}
