import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerHelper {
  static final InAppReview _inAppReview = InAppReview.instance;

  // URLを定数化
  static const String _urlAppStore = 'https://apps.apple.com/app/id6503354191';
  static const String _urlPlayStore = 'https://play.google.com/store/apps/details?id=com.kawasakicreate.youniyou.youniyou';

  static void launchStoreReview(BuildContext context) async {
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview();
    } else {
      // ストアのURLにフォールバック
      final url = Platform.isIOS ? _urlAppStore : _urlPlayStore;

      if (!await launchUrl(Uri.parse(url))) {
        throw 'Cannot launch the store URL';
      }
    }
  }
}
