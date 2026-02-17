import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/haptics.dart';
import '../../folder_picker/services/saf_service.dart';
import '../../swipe/models/swipe_file.dart';
import '../../swipe/providers/swipe_files_provider.dart';

/// Delete animation screen with vortex effect
class DeleteAnimationScreen extends ConsumerStatefulWidget {
  const DeleteAnimationScreen({super.key});

  @override
  ConsumerState<DeleteAnimationScreen> createState() =>
      _DeleteAnimationScreenState();
}

class _DeleteAnimationScreenState extends ConsumerState<DeleteAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _vortexController;
  late AnimationController _implosionController;
  late AnimationController _celebrationController;

  late List<SwipeFile> _filesToDelete;
  late int _totalSize;
  
  bool _isDeleting = false;
  bool _showSuccess = false;
  int _deletedCount = 0;
  String? _error;

  // Animation phases
  int _currentPhase = 0; // 0: gather, 1: vortex, 2: implosion, 3: celebration

  @override
  void initState() {
    super.initState();

    _vortexController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _implosionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Get files to delete
    final swipeState = ref.read(swipeFilesProvider);
    _filesToDelete = List.from(swipeState.toDelete);
    _totalSize = _filesToDelete.fold<int>(0, (sum, f) => sum + f.sizeBytes);

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _implosionController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    setState(() => _currentPhase = 0);

    // Phase 0: Gather (files lift up)
    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 1: Vortex (files spiral in)
    setState(() => _currentPhase = 1);
    _vortexController.forward();

    // Start actual deletion while animating
    _deleteFiles();

    // Haptic pulses during vortex
    for (var i = 0; i < _filesToDelete.length && i < 20; i++) {
      await Future.delayed(Duration(milliseconds: 50 + i * 10));
      Haptics.tinyPulse();
    }

    await _vortexController.forward().orCancel;

    // Phase 2: Implosion
    setState(() => _currentPhase = 2);
    Haptics.heavy();
    await _implosionController.forward().orCancel;

    // Phase 3: Celebration
    setState(() {
      _currentPhase = 3;
      _showSuccess = true;
    });
    Haptics.success();
    _celebrationController.forward();
  }

  Future<void> _deleteFiles() async {
    setState(() => _isDeleting = true);

    try {
      final safService = SAFService();

      for (final file in _filesToDelete) {
        try {
          await safService.deleteFile(file.uri);
          setState(() => _deletedCount++);
        } catch (e) {
          // Continue with other files even if one fails
          debugPrint('Failed to delete ${file.name}: $e');
        }
      }

      // Clear the delete list
      ref.read(swipeFilesProvider.notifier).clearDeleted();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.background(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Vortex background
            if (_currentPhase >= 1 && !_showSuccess) _buildVortexBackground(),

            // File thumbnails
            if (!_showSuccess) _buildFileGrid(),

            // Center vortex
            if (_currentPhase >= 1 && !_showSuccess) _buildCenterVortex(),

            // Success overlay
            if (_showSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVortexBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _vortexController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8 + (_vortexController.value * 0.5),
                colors: [
                  AppColors.delete(context)
                      .withOpacity(0.3 * _vortexController.value),
                  AppColors.background(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileGrid() {
    return AnimatedBuilder(
      animation: _vortexController,
      builder: (context, child) {
        return Stack(
          children: _filesToDelete.take(25).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _AnimatedFileItem(
              file: file,
              index: index,
              total: _filesToDelete.length.clamp(1, 25),
              phase: _currentPhase,
              vortexProgress: _vortexController.value,
              implosionProgress: _implosionController.value,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCenterVortex() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_vortexController, _implosionController]),
        builder: (context, child) {
          final scale = 0.1 +
              (_vortexController.value * 0.9) -
              (_implosionController.value * 0.8);
          final opacity = _vortexController.value - _implosionController.value;

          return Transform.scale(
            scale: scale.clamp(0.0, 1.0),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.delete(context),
                      AppColors.delete(context).withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.delete(context).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Checkmark
          Icon(
            Icons.check_circle,
            size: 96,
            color: AppColors.keep(context),
          )
              .animate(controller: _celebrationController)
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1))
              .fadeIn(),
          const SizedBox(height: AppConstants.spacingLg),

          // Freed space
          Text(
            '${FileUtils.formatBytes(_totalSize)} freed!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          )
              .animate(controller: _celebrationController)
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppConstants.spacingXs),

          // File count
          Text(
            '$_deletedCount files cleared',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted(context),
                ),
          ).animate(controller: _celebrationController).fadeIn(delay: 400.ms),

          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.delete(context),
                  ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingXl * 2),

          // Actions
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(swipeFilesProvider.notifier).reset();
                  context.go('/folder-picker');
                },
                child: const Text('Clean Another'),
              ).animate(controller: _celebrationController).fadeIn(delay: 600.ms),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => context.go('/folder-picker'),
                child: const Text('Done'),
              ).animate(controller: _celebrationController).fadeIn(delay: 700.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedFileItem extends StatelessWidget {
  final SwipeFile file;
  final int index;
  final int total;
  final int phase;
  final double vortexProgress;
  final double implosionProgress;

  const _AnimatedFileItem({
    required this.file,
    required this.index,
    required this.total,
    required this.phase,
    required this.vortexProgress,
    required this.implosionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate grid position
    final cols = 5;
    final row = index ~/ cols;
    final col = index % cols;
    final itemSize = (size.width - 80) / cols;
    final startX = 40 + col * itemSize + itemSize / 2;
    final startY = 120 + row * itemSize + itemSize / 2;
    final startPos = Offset(startX, startY);

    // Calculate animation
    final itemProgress = ((vortexProgress - index / total) * 2).clamp(0.0, 1.0);
    
    // Spiral path
    final angle = itemProgress * math.pi * 4 + (index * 0.5);
    final radius = (1 - itemProgress) * (center - startPos).distance;
    
    final currentX = center.dx + math.cos(angle) * radius * (1 - itemProgress);
    final currentY = center.dy + math.sin(angle) * radius * (1 - itemProgress);
    
    final position = Offset.lerp(startPos, Offset(currentX, currentY), itemProgress) ??
        startPos;

    // Scale down as it approaches center
    final scale = (1 - itemProgress * 0.8).clamp(0.2, 1.0);
    
    // Opacity
    final opacity = (1 - itemProgress * 1.2).clamp(0.0, 1.0);

    if (opacity <= 0 || implosionProgress > 0.5) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: position.dx - 30 * scale,
      top: position.dy - 30 * scale,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: itemProgress * math.pi * 2,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: file.typeColor(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.delete(context).withOpacity(0.3 * itemProgress),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                file.typeIcon,
                color: file.typeColor(context),
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
