import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youniyou/emun/update_request_type.dart';
import 'package:youniyou/feature/util/forced_update/update_request_provider.dart';
import 'package:youniyou/feature/util/shared_preferences/shared_preferences_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePromptDialog extends ConsumerWidget {
  const UpdatePromptDialog({
    super.key,
    required this.updateRequestType,
  });

  final UpdateRequestType? updateRequestType;

  // Androidアプリのパッケージ名
  final String androidAppId = "com.kawasakicreate.youniyou.youniyou&hl=ja-JP";
  // iOSアプリのApp Store ID
  final String iOSAppId = "6503354191";

  // Google Playストアへのリンク
  String get googlePlayStoreLink => 'https://play.google.com/store/apps/details?id=$androidAppId';

  // App Storeへのリンク
  String get appStoreLink => 'https://apps.apple.com/app/id$iOSAppId';

  // ボタンをタップしたときに呼ばれる関数
  void _launchStoreURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      // AndroidのBackボタンで閉じられないようにする
      // デバッグ時だけ外す
      onWillPop: () async => false,
      child: CupertinoAlertDialog(
        title: const Text('アプリが更新されました。\n\n最新バージョンのダウンロードをお願いします。'),
        actions: [
          // if (updateRequestType == UpdateRequestType.cancelable)
          //   TextButton(
          //     onPressed: () async {
          //       Navigator.pop(context);
          //       await ref
          //           .watch(sharedPreferencesRepositoryProvider)
          //           .save<String>(
          //             SharedPreferencesKey.cancelledUpdateDateTime,
          //             DateTime.now().toString(),
          //           );
          //       ref.invalidate(updateRequesterProvider);
          //     },
          //     child: const Text('　キャンセル'),
          //   ),
          TextButton(
            onPressed: () {
              // App Store or Google Play に飛ばす処理
              // プラットフォームに応じて適切なストアのリンクを開く
              if (Theme.of(context).platform == TargetPlatform.android) {
                _launchStoreURL(googlePlayStoreLink);
              } else if (Theme.of(context).platform == TargetPlatform.iOS) {
                _launchStoreURL(appStoreLink);
              }
            },
            child: const Text('アップデートする'),
          ),
        ],
      ),
    );
  }
}
