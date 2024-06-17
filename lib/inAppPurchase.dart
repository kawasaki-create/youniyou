import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final inAppPurchaseManagerProvider = ChangeNotifierProvider((ref) => InAppPurchaseManager());

class InAppPurchaseManager extends ChangeNotifier {
  bool isSubscribed = false;
  late Offerings offerings;
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> initInAppPurchase() async {
    try {
      await Purchases.setDebugLogsEnabled(true);
      late PurchasesConfiguration configuration;

      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration('Android用のRevenuecat APIキー');
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration('appl_hfFalSoPmwPUewcYATNwVWuwmcN');
      }
      await Purchases.configure(configuration);
      offerings = await Purchases.getOfferings();
      final result = await Purchases.logIn(auth.currentUser!.uid);

      await getPurchaserInfo(result.customerInfo);

      print("アクティブなアイテム ${result.customerInfo.entitlements.active.keys}");
    } catch (e) {
      print("initInAppPurchase error caught! ${e.toString()}");
    }
  }

  Future<void> getPurchaserInfo(CustomerInfo customerInfo) async {
    try {
      isSubscribed = await updatePurchases(customerInfo, 'Monthly_subscription');
      notifyListeners();
    } on PlatformException catch (e) {
      print("getPurchaserInfo error ${PurchasesErrorHelper.getErrorCode(e).toString()}");
    }
  }

  Future<bool> updatePurchases(CustomerInfo purchaserInfo, String entitlement) async {
    var isPurchased = false;
    final entitlements = purchaserInfo.entitlements.all;
    if (entitlements.isEmpty) {
      isPurchased = false;
    } else if (!entitlements.containsKey(entitlement)) {
      isPurchased = false;
    } else if (entitlements[entitlement]!.isActive) {
      isPurchased = true;
    } else {
      isPurchased = false;
    }
    return isPurchased;
  }

  Future<void> makePurchase(String offeringsName) async {
    try {
      Package? package;
      package = offerings.all[offeringsName]?.monthly;
      if (package != null) {
        await Purchases.logIn(auth.currentUser!.uid);
        CustomerInfo customerInfo = await Purchases.purchasePackage(package);
        await getPurchaserInfo(customerInfo);
      }
    } on PlatformException catch (e) {
      print("purchase repo makePurchase error ${e.toString()}");
    }
  }

  Future<void> restorePurchase(String entitlement) async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final isActive = await updatePurchases(customerInfo, entitlement);
      if (!isActive) {
        print("購入情報なし");
      } else {
        await getPurchaserInfo(customerInfo);
        print("${entitlement} 購入情報あり　復元する");
      }
    } on PlatformException catch (e) {
      print("purchase repo  restorePurchase error ${e.toString()}");
    }
  }
}

class RevenueCat {
  /// RevenueCatの初期化
  Future<void> initRC() async {
    final androidAPIKey = 'goog_iQErEaMQLgJYuACXSxXKdcnZvIh';
    final iosAPIKey = 'appl_hfFalSoPmwPUewcYATNwVWuwmcN';
    final revenueCatAPIKey = Platform.isAndroid ? androidAPIKey : iosAPIKey;

    try {
      /// デバッグモードでログ出力
      await Purchases.setDebugLogsEnabled(true);

      /// RevenueCatと連携
      final uid = 'ユーザーID';
      await Purchases.setup(revenueCatAPIKey, appUserId: uid);
    } on PlatformException catch (e) {
      /// エラーハンドリング
      print("Error initializing RevenueCat: $e");
    }
  }

  /// 購入情報の取得・購入
  Future<void> purchase() async {
    /// 購入アイテム（Package）取得
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.monthly;
    if (package == null) {
      print("No package available for purchase");
      return;
    }

    try {
      /// 購入処理
      await Purchases.purchasePackage(package);
    } on PlatformException catch (e) {
      /// エラーハンドリング
      print("Error during purchase: $e");
    }
  }

  /// サブスク状態取得
  Future<bool> isSubscribed() async {
    try {
      /// サブスクリプション（Entitlement）取得
      final customerInfo = await Purchases.getCustomerInfo();
      const entitlementId = 'pro'; // RevenueCatダッシュボードで設定したEntitlement ID
      final entitlement = customerInfo.entitlements.all[entitlementId];
      if (entitlement == null) {
        print("Entitlement not found for ID: $entitlementId");
        return false;
      }

      /// サブスクリプション状態取得（有効or無効）
      final isSubscribing = entitlement.isActive;
      print("Subscription status for $entitlementId: $isSubscribing");

      // サブスクリプション状態を返す
      return isSubscribing;
    } catch (e) {
      // エラーハンドリング
      print("Error fetching subscription status: $e");
      return false;
    }
  }
}
