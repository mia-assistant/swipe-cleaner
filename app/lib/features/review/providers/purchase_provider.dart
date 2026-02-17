import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Purchase state
class PurchaseState {
  final bool isUnlocked;
  final bool isLoading;
  final String? error;
  final String? price;

  const PurchaseState({
    this.isUnlocked = false,
    this.isLoading = false,
    this.error,
    this.price,
  });

  PurchaseState copyWith({
    bool? isUnlocked,
    bool? isLoading,
    String? error,
    String? price,
  }) {
    return PurchaseState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      price: price ?? this.price,
    );
  }
}

/// Purchase provider
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  return PurchaseNotifier();
});

/// Purchase state notifier
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  static const _purchaseKey = 'swipeclear_unlocked';
  static const _productId = 'swipecleaner_pro';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _productDetails;

  PurchaseNotifier() : super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadPurchaseState();
    await _initStore();
  }

  Future<void> _loadPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool(_purchaseKey) ?? false;
    state = state.copyWith(isUnlocked: isUnlocked);
  }

  Future<void> _initStore() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: 'Purchase failed. Please try again.',
        );
      },
    );

    // Query product details
    final response = await _iap.queryProductDetails({_productId});
    if (response.productDetails.isNotEmpty) {
      _productDetails = response.productDetails.first;
      state = state.copyWith(price: _productDetails!.price);
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverProduct();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            isLoading: false,
            error: 'Purchase failed. Please try again.',
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(isLoading: false);
          break;
        case PurchaseStatus.pending:
          state = state.copyWith(isLoading: true);
          break;
      }
    }
  }

  Future<void> _deliverProduct() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purchaseKey, true);
    state = state.copyWith(isUnlocked: true, isLoading: false);
  }

  /// Initiate purchase
  Future<void> purchase() async {
    if (_productDetails == null) {
      state = state.copyWith(error: 'Store not available. Please try again.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final purchaseParam = PurchaseParam(productDetails: _productDetails!);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    await _iap.restorePurchases();

    // Give the stream a moment to deliver restored purchases
    await Future.delayed(const Duration(seconds: 2));

    if (!state.isUnlocked && mounted) {
      state = state.copyWith(
        isLoading: false,
        error: 'No previous purchase found.',
      );
    }
  }

  /// For testing: unlock directly
  Future<void> unlockForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purchaseKey, true);
    state = state.copyWith(isUnlocked: true);
  }

  /// For testing: reset purchase
  Future<void> resetPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_purchaseKey);
    state = state.copyWith(isUnlocked: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
