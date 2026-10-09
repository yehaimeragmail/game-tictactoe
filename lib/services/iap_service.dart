import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Store for Tic Tac Toe: one-time Pro unlock + consumable tip jar.
///
/// Product IDs (no dots, no underscores, game name included — MASTER_RULES):
///   tictactoepro        — one-time NON-consumable Pro unlock
///   tictactoecoffee     — consumable tip
///   tictactoechocolate  — consumable tip
///
/// The products must be created by Wajiha in Play Console; until then (or on
/// any store error) the service degrades gracefully — the UI shows the store
/// as "available after store setup" instead of crashing or hanging.
class TttStore {
  static const proId = 'tictactoepro';
  static const coffeeId = 'tictactoecoffee';
  static const chocolateId = 'tictactoechocolate';
  static const productIds = {proId, coffeeId, chocolateId};

  final InAppPurchase _iap = InAppPurchase.instance;

  bool available = false;
  Map<String, ProductDetails> products = {};
  String? error;
  bool _initialized = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Called when the one-time Pro purchase completes (buy or restore).
  /// The UI wires this to `settings.setPro(true)`.
  Future<void> Function()? onProUnlocked;

  /// Last completed purchase, for a thank-you note. Reset by the UI.
  final ValueNotifier<String?> lastThanks = ValueNotifier(null);

  ProductDetails? get proProduct => products[proId];
  ProductDetails? get coffeeProduct => products[coffeeId];
  ProductDetails? get chocolateProduct => products[chocolateId];

  /// True when the store answered and at least one product is configured.
  bool get storeReady => available && products.isNotEmpty;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      available = await _iap.isAvailable();
      if (!available) {
        error = 'Store unavailable on this device';
        return;
      }
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (_) {},
        cancelOnError: false,
      );
      final resp = await _iap.queryProductDetails(productIds);
      if (resp.error != null) {
        error = 'Could not load products';
        return;
      }
      products = {for (final p in resp.productDetails) p.id: p};
      if (resp.notFoundIDs.isNotEmpty) {
        // Products not created in Play Console yet — normal before release.
        error = 'Available after store setup';
      }
    } catch (_) {
      available = false;
      error = 'Store error';
    }
  }

  void _onPurchases(List<PurchaseDetails> list) {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == proId) {
          lastThanks.value = 'Welcome to Pro! Every table is yours.';
          onProUnlocked?.call();
        } else if (p.productID == chocolateId) {
          lastThanks.value = 'Thank you for the chocolate!';
        } else if (p.productID == coffeeId) {
          lastThanks.value = 'Thank you for the coffee!';
        }
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p).catchError((_) {});
      }
    }
  }

  /// One-time Pro unlock. Returns false when the product isn't configured.
  Future<bool> buyPro() async {
    final product = proProduct;
    if (product == null) return false;
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      return false;
    }
  }

  /// Consumable tip. Returns false when the product isn't configured.
  Future<bool> buyTip(ProductDetails product) async {
    try {
      return await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      return false;
    }
  }

  /// Re-delivers past purchases (e.g. Pro bought on another device).
  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    lastThanks.dispose();
  }
}
