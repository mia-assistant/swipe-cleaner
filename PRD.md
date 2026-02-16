# SwipeClear — Product Requirements Document

> Tinder-style swipe interface to clean your Downloads folder

**Package:** `com.manuelpa.swipecleaner`  
**Version:** 1.0.0  
**Platform:** Android (Flutter)  
**Created:** 2026-02-15

---

## 1. Overview

SwipeClear turns the tedious task of cleaning your Downloads folder into a satisfying, game-like experience. Swipe left to delete, swipe right to keep. See exactly what you're clearing. Pay once to delete.

### Core Value Proposition
- **Speed:** Clean 100+ files in under 2 minutes
- **Clarity:** See thumbnails before deciding
- **Satisfaction:** Dopamine-inducing delete animation
- **Simplicity:** No account, no cloud, no complexity

---

## 2. Design System

### 2.1 Theme
- **Mode:** Follow system (light/dark auto-switch)
- **Style:** Minimal, clean, focused
- **Motion:** Smooth, physics-based animations

### 2.2 Colors

#### Light Theme
| Role | Color | Usage |
|------|-------|-------|
| Background | `#FAFAFA` | Main scaffold |
| Surface | `#FFFFFF` | Cards, sheets |
| Primary | `#1A1A1A` | Text, icons |
| Accent | `#6366F1` | Buttons, highlights (Indigo 500) |
| Keep | `#10B981` | Swipe right glow (Emerald 500) |
| Delete | `#EF4444` | Swipe left glow (Red 500) |
| Muted | `#9CA3AF` | Secondary text |

#### Dark Theme
| Role | Color | Usage |
|------|-------|-------|
| Background | `#0A0A0A` | Main scaffold |
| Surface | `#171717` | Cards, sheets |
| Primary | `#FAFAFA` | Text, icons |
| Accent | `#818CF8` | Buttons, highlights (Indigo 400) |
| Keep | `#34D399` | Swipe right glow (Emerald 400) |
| Delete | `#F87171` | Swipe left glow (Red 400) |
| Muted | `#6B7280` | Secondary text |

### 2.3 Typography
- **Font:** System default (Roboto on Android)
- **Headline Large:** 32sp, Bold — Screen titles
- **Headline Medium:** 24sp, SemiBold — Section headers
- **Title Large:** 20sp, Medium — Card titles
- **Body Large:** 16sp, Regular — Primary content
- **Body Medium:** 14sp, Regular — Secondary content
- **Label:** 12sp, Medium — Badges, captions

### 2.4 Spacing Scale
```
4, 8, 12, 16, 24, 32, 48, 64
```

### 2.5 Border Radius
- Cards: 16dp
- Buttons: 12dp
- Badges: 6dp
- Full round: 999dp (pills, FABs)

### 2.6 Shadows (Light mode only)
- Card: `0 2dp 8dp rgba(0,0,0,0.08)`
- Elevated: `0 4dp 16dp rgba(0,0,0,0.12)`

---

## 3. User Flow

### 3.1 First Launch
```
┌─────────────────────────────────────┐
│                                     │
│         [App Icon - Large]          │
│                                     │
│           SwipeClear                │
│                                     │
│    Clean your Downloads folder      │
│       with satisfying swipes        │
│                                     │
│     ┌─────────────────────────┐     │
│     │    Get Started    →     │     │
│     └─────────────────────────┘     │
│                                     │
│      Swipe left = delete            │
│      Swipe right = keep             │
│                                     │
│   One-time purchase: $3.99          │
│                                     │
└─────────────────────────────────────┘
```

### 3.2 Folder Selection (SAF Picker)
```
┌─────────────────────────────────────┐
│  ←  Select Folder                   │
├─────────────────────────────────────┤
│                                     │
│    📁  Choose a folder to clean     │
│                                     │
│    We recommend starting with       │
│    your Downloads folder            │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Free to swipe · $3.99 to delete││
│  └─────────────────────────────────┘│
│                                     │
│     ┌─────────────────────────┐     │
│     │   Open Folder Picker    │     │
│     └─────────────────────────┘     │
│                                     │
│    ℹ️  We can only delete files     │
│       you explicitly swipe left on  │
│                                     │
└─────────────────────────────────────┘
```

**Upfront Pricing Clarity:**
- Price badge shown on folder picker screen every time
- Users always know the deal before investing time swiping
- Prevents "bait and switch" feeling at paywall

### 3.3 Swipe Interface (Main Screen)
```
┌─────────────────────────────────────┐
│  Downloads              47 files    │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │                               │  │
│  │      [File Thumbnail]         │  │
│  │         70% height            │  │
│  │                               │  │
│  │                               │  │
│  ├───────────────────────────────┤  │
│  │  📄 quarterly_report.pdf      │  │
│  │  2.4 MB · Dec 15, 2025        │  │
│  │  ┌─────┐                      │  │
│  │  │ PDF │                      │  │
│  │  └─────┘                      │  │
│  └───────────────────────────────┘  │
│                                     │
│    ← DELETE         KEEP →          │
│                                     │
├─────────────────────────────────────┤
│  🗑️ 12 files · 234 MB    [Review]   │
└─────────────────────────────────────┘
```

**Swipe Behavior:**
- Swipe threshold: 100dp
- Rotation: ±15° max based on swipe direction
- Opacity: Card fades as it exits
- Background glow: Red (left) or Green (right) intensifies with swipe
- Haptic: Light impact on threshold cross, medium on release
- Stack: Show 2 cards behind (scaled 0.95, 0.9 and offset -8dp, -16dp)

### 3.4 Review Screen (Pre-Delete)
```
┌─────────────────────────────────────┐
│  ←  Review                          │
├─────────────────────────────────────┤
│                                     │
│     Ready to clear                  │
│                                     │
│     ┌─────────────────────────┐     │
│     │       23 files          │     │
│     │       847 MB            │     │
│     └─────────────────────────┘     │
│                                     │
│  ┌─────┬─────┬─────┬─────┬─────┐   │
│  │ 📄  │ 🖼️  │ 📄  │ 📦  │ 🎵  │   │
│  ├─────┼─────┼─────┼─────┼─────┤   │
│  │ 📄  │ 📄  │ 🖼️  │ 📄  │ 📱  │   │
│  ├─────┼─────┼─────┼─────┼─────┤   │
│  │ 🖼️  │ 📄  │ 📄  │ 🎵  │ 📄  │   │
│  └─────┴─────┴─────┴─────┴─────┘   │
│                                     │
│        Tap any to undo              │
│                                     │
│     ┌─────────────────────────┐     │
│     │   🗑️  Clear All  $3.99   │     │
│     └─────────────────────────┘     │
│                                     │
│     Already purchased? Restore      │
│                                     │
└─────────────────────────────────────┘
```

**Grid behavior:**
- Tap thumbnail → remove from delete list (animate out with scale + fade)
- Scroll if more than 15 files
- Real-time counter updates

### 3.5 Paywall (Inline, not blocking)
```
┌─────────────────────────────────────┐
│                                     │
│        ✨ Unlock SwipeClear         │
│                                     │
│     One-time purchase. Forever.     │
│                                     │
│     ┌─────────────────────────┐     │
│     │                         │     │
│     │         $3.99           │     │
│     │                         │     │
│     │   [Unlock SwipeClear]   │     │
│     │                         │     │
│     └─────────────────────────┘     │
│                                     │
│     ✓ Unlimited folder cleaning     │
│     ✓ All future updates            │
│     ✓ No subscriptions ever         │
│                                     │
│              Cancel                 │
│                                     │
└─────────────────────────────────────┘
```

### 3.6 Delete Animation (THE MOMENT)

**Concept: Vortex Obliteration**

Files spiral into a central vortex/black hole, shrinking and accelerating as they approach the center. Each file leaves a particle trail. When the last file enters, a satisfying implosion followed by an expansion wave.

```
Phase 1: Gather (400ms)
- Thumbnail grid items lift slightly (translateZ)
- Subtle glow begins at center

Phase 2: Vortex (800ms)
- Files spiral inward, one by one (staggered 30ms)
- Each file: rotate + scale down + move to center
- Particle trails follow each file
- Center vortex pulses with each absorbed file
- Haptic: tiny pulse per file

Phase 3: Implosion (200ms)
- All remaining elements snap to center
- Screen flash (subtle)
- Strong haptic

Phase 4: Expansion (400ms)  
- Shockwave ripple from center
- Background shifts to success color (green tint)
- Counter animates: "0 MB" → final freed space

Phase 5: Celebration (600ms)
- Large checkmark fades in
- "2.3 GB freed!" scales up
- Confetti particles (subtle, not childish)
- Haptic: success pattern
```

### 3.7 Success Screen
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│              ✓                      │
│                                     │
│         2.3 GB freed!               │
│                                     │
│      23 files cleared from          │
│          Downloads                  │
│                                     │
│                                     │
│     ┌─────────────────────────┐     │
│     │    Clean Another →      │     │
│     └─────────────────────────┘     │
│                                     │
│            Done                     │
│                                     │
└─────────────────────────────────────┘
```

### 3.8 Empty State (No Files)
```
┌─────────────────────────────────────┐
│  Downloads                          │
├─────────────────────────────────────┤
│                                     │
│                                     │
│           ✨                        │
│                                     │
│      Already spotless!              │
│                                     │
│   This folder has no files to       │
│   clean. Nice work.                 │
│                                     │
│     ┌─────────────────────────┐     │
│     │   Pick Another Folder   │     │
│     └─────────────────────────┘     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

---

## 4. Technical Architecture

### 4.1 Project Structure
```
lib/
├── main.dart
├── app.dart                    # MaterialApp, theme, routing
├── core/
│   ├── theme/
│   │   ├── app_theme.dart      # ThemeData definitions
│   │   ├── app_colors.dart     # Color constants
│   │   └── app_typography.dart # Text styles
│   ├── constants/
│   │   └── app_constants.dart  # Spacing, durations, etc.
│   └── utils/
│       ├── file_utils.dart     # Size formatting, type detection
│       └── haptics.dart        # Haptic feedback helpers
├── features/
│   ├── onboarding/
│   │   ├── screens/
│   │   │   └── onboarding_screen.dart
│   │   └── widgets/
│   ├── folder_picker/
│   │   ├── screens/
│   │   │   └── folder_picker_screen.dart
│   │   ├── services/
│   │   │   └── saf_service.dart
│   │   └── widgets/
│   ├── swipe/
│   │   ├── screens/
│   │   │   └── swipe_screen.dart
│   │   ├── controllers/
│   │   │   └── swipe_controller.dart
│   │   ├── models/
│   │   │   └── swipe_file.dart
│   │   └── widgets/
│   │       ├── swipe_card.dart
│   │       ├── swipe_stack.dart
│   │       ├── file_thumbnail.dart
│   │       └── swipe_indicators.dart
│   ├── review/
│   │   ├── screens/
│   │   │   └── review_screen.dart
│   │   └── widgets/
│   │       ├── file_grid.dart
│   │       └── delete_counter.dart
│   ├── purchase/
│   │   ├── screens/
│   │   │   └── paywall_screen.dart
│   │   ├── services/
│   │   │   └── purchase_service.dart
│   │   └── widgets/
│   ├── delete/
│   │   ├── screens/
│   │   │   └── delete_animation_screen.dart
│   │   ├── services/
│   │   │   └── delete_service.dart
│   │   └── widgets/
│   │       ├── vortex_animation.dart
│   │       └── success_celebration.dart
│   └── success/
│       └── screens/
│           └── success_screen.dart
└── shared/
    └── widgets/
        ├── app_button.dart
        └── app_scaffold.dart
```

### 4.2 Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # File Access (SAF)
  shared_storage: ^0.8.0
  
  # Thumbnails
  flutter_file_preview: ^1.0.0    # Or thumbnailer if available
  pdf_render: ^1.4.3              # PDF first page
  
  # In-App Purchase
  in_app_purchase: ^3.1.13
  
  # Animations
  flutter_animate: ^4.3.0
  lottie: ^3.0.0                  # Optional: for complex animations
  
  # Haptics
  vibration: ^1.8.4
  
  # Storage
  shared_preferences: ^2.2.2      # Purchase state, seen onboarding
  
  # Utils
  path: ^1.8.3
  intl: ^0.19.0                   # Date formatting
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### 4.3 State Management

Using Riverpod for clean, testable state:

```dart
// Swipe state
final swipeFilesProvider = StateNotifierProvider<SwipeFilesNotifier, SwipeState>((ref) {
  return SwipeFilesNotifier();
});

class SwipeState {
  final List<SwipeFile> files;
  final List<SwipeFile> toDelete;
  final List<SwipeFile> toKeep;
  final int currentIndex;
  final bool isLoading;
}

// Purchase state
final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  return PurchaseNotifier();
});

class PurchaseState {
  final bool isUnlocked;
  final bool isLoading;
  final String? error;
}
```

### 4.4 SAF Integration

```dart
class SAFService {
  /// Open folder picker and get persistent URI
  Future<Uri?> pickFolder() async {
    final uri = await openDocumentTree();
    if (uri != null) {
      // Persist permission
      await persistPermission(uri);
    }
    return uri;
  }
  
  /// List files in folder
  Future<List<SwipeFile>> listFiles(Uri folderUri) async {
    final files = await listDocuments(folderUri);
    return files.map((doc) => SwipeFile.fromDocument(doc)).toList();
  }
  
  /// Delete files by URI
  Future<void> deleteFiles(List<Uri> fileUris) async {
    for (final uri in fileUris) {
      await deleteDocument(uri);
    }
  }
}
```

### 4.5 File Model

```dart
class SwipeFile {
  final String uri;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modified;
  final FileType type;
  final String? thumbnailPath;
  
  String get formattedSize => formatBytes(sizeBytes);
  String get formattedDate => DateFormat.yMMMd().format(modified);
  
  IconData get typeIcon => switch (type) {
    FileType.image => Icons.image_outlined,
    FileType.pdf => Icons.picture_as_pdf_outlined,
    FileType.audio => Icons.audio_file_outlined,
    FileType.video => Icons.video_file_outlined,
    FileType.archive => Icons.folder_zip_outlined,
    FileType.apk => Icons.android_outlined,
    FileType.document => Icons.description_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

enum FileType {
  image, pdf, audio, video, archive, apk, document, spreadsheet, unknown
}
```

---

## 5. Screen Specifications

### 5.1 Onboarding Screen
- **Route:** `/onboarding`
- **Shows:** First launch only (check SharedPreferences)
- **Components:**
  - App icon (96dp)
  - Title: "SwipeClear"
  - Subtitle: "Clean your Downloads folder with satisfying swipes"
  - Swipe instruction icons
  - Price disclosure: "One-time purchase: $3.99"
  - CTA button: "Get Started"
- **Navigation:** → Folder Picker

### 5.2 Folder Picker Screen
- **Route:** `/folder-picker`
- **Components:**
  - Folder icon
  - Instruction text
  - "Open Folder Picker" button
  - Info text about permissions
- **Actions:**
  - Trigger SAF picker
  - On success → Swipe Screen
  - On cancel → Stay

### 5.3 Swipe Screen
- **Route:** `/swipe`
- **Components:**
  - AppBar: Folder name, file count
  - SwipeStack: 3 visible cards
  - Swipe indicators: "← DELETE" and "KEEP →"
  - Bottom bar: Delete counter + Review button
- **Gestures:**
  - Horizontal drag on card
  - Tap card → expand preview (optional v1.1)
- **State:**
  - currentIndex
  - toDelete list
  - toKeep list
- **Navigation:** 
  - All swiped → Review Screen
  - Review button → Review Screen

### 5.4 Review Screen
- **Route:** `/review`
- **Components:**
  - Header: "Ready to clear"
  - Counter card: file count + total size
  - Thumbnail grid (5 columns)
  - Tap instruction
  - CTA: "Clear All $3.99" or "Clear All" (if purchased)
  - Restore purchases link
- **Actions:**
  - Tap thumbnail → remove from list
  - CTA → Check purchase → Paywall or Delete
- **Navigation:**
  - Back → Swipe Screen
  - Clear → Paywall (if needed) → Delete Animation

### 5.5 Paywall Screen
- **Route:** `/paywall` (modal bottom sheet)
- **Components:**
  - Title: "Unlock SwipeClear"
  - Price: "$3.99"
  - Benefits list
  - Purchase button
  - Cancel button
- **Actions:**
  - Purchase → IAP flow → Success → Delete Animation
  - Cancel → Dismiss

### 5.6 Delete Animation Screen
- **Route:** `/delete` (full screen, no back)
- **Components:**
  - Vortex animation canvas
  - File thumbnails (animated)
  - Particle system
  - Counter animation
- **Duration:** ~2.5 seconds total
- **Navigation:** Auto → Success Screen

### 5.7 Success Screen
- **Route:** `/success`
- **Components:**
  - Checkmark icon (animated)
  - "X GB freed!" (animated counter)
  - "X files cleared from [Folder]"
  - "Clean Another" button
  - "Done" text button
- **Navigation:**
  - Clean Another → Folder Picker
  - Done → Exit app or Home

---

## 6. Animations Specification

### 6.1 Swipe Card Physics
```dart
// Spring animation for snap back
final spring = SpringDescription(
  mass: 1,
  stiffness: 500,
  damping: 25,
);

// Swipe velocity threshold
const velocityThreshold = 1000.0; // pixels/second

// Position threshold  
const positionThreshold = 100.0; // dp
```

### 6.2 Card Stack Animation
```dart
// Background cards
for (i in [1, 2]) {
  scale: 1.0 - (i * 0.05),      // 0.95, 0.90
  translateY: i * -8.0,          // -8, -16
  opacity: 1.0 - (i * 0.15),    // 0.85, 0.70
}

// On swipe complete, cards animate forward
duration: 200ms
curve: Curves.easeOut
```

### 6.3 Glow Animation
```dart
// Intensity based on drag position
final intensity = (dragX.abs() / screenWidth).clamp(0.0, 1.0);

// Glow container
Container(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      colors: [
        (dragX < 0 ? deleteColor : keepColor).withOpacity(intensity * 0.3),
        Colors.transparent,
      ],
    ),
  ),
)
```

### 6.4 Vortex Delete Animation

```dart
// Phase timings
const gatherDuration = Duration(milliseconds: 400);
const vortexDuration = Duration(milliseconds: 800);
const implosionDuration = Duration(milliseconds: 200);
const expansionDuration = Duration(milliseconds: 400);
const celebrationDuration = Duration(milliseconds: 600);

// Per-file vortex animation
void animateFileToVortex(int index) {
  final delay = Duration(milliseconds: index * 30);
  
  controller.forward();
  // Spiral path using parametric equation
  // x = r(t) * cos(θ(t))
  // y = r(t) * sin(θ(t))
  // where r decreases and θ increases over time
}
```

---

## 7. In-App Purchase

### 7.1 Product Configuration
- **Product ID:** `swipeclear_unlock`
- **Type:** Non-consumable
- **Price:** $3.99 USD

### 7.2 Purchase Flow
1. User taps "Clear All $3.99"
2. Check if already purchased (local cache + store query)
3. If not purchased → Show paywall
4. User taps "Unlock SwipeClear"
5. Trigger IAP flow
6. On success → Save to SharedPreferences + proceed to delete
7. On failure → Show error, stay on review

### 7.3 Restore Purchases
- Available on Review screen
- Queries store for past purchases
- Updates local state if found

---

## 8. Error Handling

### 8.1 Permission Denied
- Show explanation dialog
- "Open Settings" button to grant manually

### 8.2 No Files Found
- Show empty state (already clean)
- Offer to pick different folder

### 8.3 Delete Failed
- Show which files failed
- Offer retry or skip

### 8.4 Purchase Failed
- Show error message from store
- Keep user on review screen
- Allow retry

---

## 9. Analytics Events (Future)

| Event | Parameters |
|-------|------------|
| `app_opened` | - |
| `onboarding_completed` | - |
| `folder_selected` | `file_count`, `total_size` |
| `swipe_completed` | `kept`, `deleted`, `duration_seconds` |
| `review_opened` | `file_count`, `total_size` |
| `paywall_shown` | - |
| `purchase_started` | - |
| `purchase_completed` | `price` |
| `purchase_failed` | `error` |
| `delete_completed` | `file_count`, `size_freed` |

---

## 10. Accessibility

- All interactive elements have semantic labels
- Minimum touch target: 48dp
- Color contrast: WCAG AA minimum
- Screen reader: Announce card content, swipe actions
- Reduce motion: Skip particle effects, simplify animations

---

## 11. Testing Checklist

### Unit Tests
- [ ] File size formatting
- [ ] File type detection
- [ ] Swipe state management
- [ ] Purchase state management

### Widget Tests
- [ ] Swipe card renders correctly
- [ ] Swipe gestures work
- [ ] Review grid updates on tap
- [ ] Theme switches correctly

### Integration Tests
- [ ] Full flow: onboarding → swipe → review → delete
- [ ] Purchase flow (sandbox)
- [ ] SAF permission flow

### Manual Tests
- [ ] Large folder (500+ files)
- [ ] Various file types render correctly
- [ ] Animation performance (60fps)
- [ ] Haptics feel right
- [ ] Dark/light theme both look good

---

## 12. Launch Checklist

- [ ] App icon (all sizes)
- [ ] Splash screen
- [ ] Store screenshots (phone + tablet)
- [ ] Store description
- [ ] Privacy policy URL
- [ ] IAP product created in Play Console
- [ ] Release signing configured
- [ ] ProGuard rules (if needed)
- [ ] Version code/name set

---

## 13. Post-MVP Roadmap

### v1.1
- [ ] Multiple folder support
- [ ] Sort options (date, size, type)
- [ ] Filter by file type
- [ ] Undo last swipe button

### v1.2
- [ ] "Move to folder" gesture (swipe up)
- [ ] Quick folders (Receipts, Work, Archive)
- [ ] Statistics screen (total cleared over time)

### v1.3
- [ ] Scheduled cleaning reminders
- [ ] Widget showing folder size
- [ ] Batch select in review

---

*Document version: 1.0*  
*Last updated: 2026-02-15*
