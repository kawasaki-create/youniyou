import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youniyou/common_widget/update_prompt_dialog.dart';
import 'package:youniyou/emun/update_request_type.dart';
import 'package:youniyou/feature/util/forced_update/update_request_provider.dart';
import 'package:youniyou/main.dart';
import 'package:youniyou/routes/friends_route.dart';
import 'package:youniyou/routes/home_route.dart';
import 'package:youniyou/routes/settings_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youniyou/todo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admobHelper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:youniyou/inAppPurchase.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);
final todoProvider = StateProvider<Todo>((ref) => Todo());

class RootWidgets extends HookConsumerWidget {
  const RootWidgets({super.key});

  static const _RootWidgetIcons = [
    Icons.calendar_today,
    Icons.people,
    // Icons.settings, // 設定画面は一旦削除
  ];

  static const _RootWidgetItemNames = [
    'スケジュール',
    '友達',
    // '設定', // 設定画面は一旦削除
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Admobの初期化
    AdmobHelper admobHelper = AdmobHelper();
    // final revenueCat = RevenueCat();
    // revenueCat.initRC();
    final isSubscribed = ref.watch(subscriptionProvider);

    // updateの確認
    final updateRequestType = ref.watch(updateRequesterProvider).whenOrNull(
          skipLoadingOnRefresh: false,
          data: (updateRequestType) => updateRequestType,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (updateRequestType == UpdateRequestType.cancelable || updateRequestType == UpdateRequestType.forcibly) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return UpdatePromptDialog(
              updateRequestType: updateRequestType,
            );
          },
        );
      }
    });

    final selectedIndex = ref.watch(selectedIndexProvider);
    final todo = ref.watch(todoProvider);
    final routes = [
      Home(),
      Friends(),
      SettingsRoute(),
    ];

    void _onItemTapped(int index) {
      ref.read(selectedIndexProvider.notifier).state = index;
    }

    List<BottomNavigationBarItem> _bottomNavigationBarItems = List.generate(
      _RootWidgetItemNames.length,
      (index) => BottomNavigationBarItem(
        icon: Icon(
          _RootWidgetIcons[index],
          color: index == selectedIndex ? Colors.black87 : Colors.black26,
        ),
        label: _RootWidgetItemNames[index],
      ),
    );

    Future<void> _showTodoDialog() async {
      final user = FirebaseAuth.instance.currentUser;
      final friendsSnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).get();
      final friends = friendsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      final todo = Todo(); // 新しいTodoオブジェクトを作成
      todo.id = user?.uid;

      String? selectedFriendId = todo.friendId;
      DateTime? startDateTime = todo.startDateTime;
      DateTime? endDateTime = todo.endDateTime;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('予定の追加'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text('対象者を選択：'),
                      DropdownButton<String>(
                        value: todo.friendId,
                        onChanged: (String? newValue) {
                          setState(() {
                            todo.friendId = newValue;
                          });
                        },
                        items: friends.map((friend) {
                          return DropdownMenuItem<String>(
                            value: friend['id'],
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(friend['icon']),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(friend['name']),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      Text('開始日時：'),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: todo.startDateTime ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );

                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(todo.startDateTime ?? DateTime.now()),
                            );

                            if (time != null) {
                              setState(() {
                                todo.startDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Text(todo.startDateTime != null ? '${todo.startDateTime!.year}/${todo.startDateTime!.month}/${todo.startDateTime!.day} ${todo.startDateTime!.hour}:${todo.startDateTime!.minute}' : '開始日時を選択'),
                      ),
                      SizedBox(height: 16),
                      Text('終了日時：'),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime ?? startDateTime ?? DateTime.now(),
                            firstDate: startDateTime ?? DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime ?? startDateTime ?? DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                todo.endDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Text(todo.endDateTime != null ? '${todo.endDateTime!.year}/${todo.endDateTime!.month}/${todo.endDateTime!.day} ${todo.endDateTime!.hour}:${todo.endDateTime!.minute}' : '終了日時を選択'),
                      ),
                      SizedBox(height: 16),
                      Text('内容：'),
                      TextFormField(
                        initialValue: todo.description,
                        onChanged: (value) {
                          todo.description = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('リセット'),
                    onPressed: () {
                      ref.read(todoProvider.notifier).state = Todo();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('登録'),
                    onPressed: () async {
                      final error = todo.validateInputsWithFriend(todo.friendId, todo.startDateTime, todo.endDateTime, todo.description);
                      if (error != null) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('エラー'),
                              content: Text(error),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection('todo').add(todo.toMap());
                      ref.read(todoProvider.notifier).state = Todo();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return ScaffoldMessenger(
      child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: routes[selectedIndex],
                ),
                if (isSubscribed == false)
                  TextButton(
                    onPressed: () async {
                      return showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Scaffold(
                            body: Container(
                              child: StatefulBuilder(
                                builder: (context, StateSetter setState) {
                                  return SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          '有料会員登録',
                                          style: TextStyle(fontSize: 25, decoration: TextDecoration.underline),
                                        ),
                                        Text(''),
                                        Text('有料会員になると、以下の特典があります🤗'),
                                        Card(
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  FaIcon(FontAwesomeIcons.ad),
                                                  Text('　広告非表示'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  FaIcon(FontAwesomeIcons.userPlus),
                                                  Text('　6人以上の友達追加'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(''),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('有料会員登録する　　'),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey,
                                                foregroundColor: Colors.white,
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () async {
                                                final inAppPurchaseManager = ref.read(inAppPurchaseManagerProvider);

                                                /// 購入アイテム（Package）取得
                                                final offerings = await Purchases.getOfferings();

                                                try {
                                                  // 購入処理
                                                  await RevenueCat().purchase();

                                                  // 購入完了メッセージを表示
                                                  await ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('ご購入ありがとうございます。有料会員登録が完了しました😊'),
                                                    ),
                                                  );
                                                  await Future.delayed(Duration(seconds: 1));
                                                  // ログイン画面に遷移
                                                  await Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => MyApp()),
                                                    (_) => false,
                                                  );
                                                } on PlatformException catch (e) {
                                                  // エラーハンドリング
                                                  await ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('購入処理に失敗しました🥲'),
                                                    ),
                                                  );
                                                  await Future.delayed(Duration(seconds: 1));
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: Text('1ヶ月：¥300'),
                                            ),
                                          ],
                                        ),
                                        Text(''),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () async {
                                            // try {
                                            //   CustomerInfo customerInfo = await Purchases.restorePurchases();
                                            //   // ユーザーが購入済みかどうかを確認する
                                            //   bool isUserPurchased = customerInfo.activeSubscriptions.isNotEmpty || customerInfo.entitlements.active.isNotEmpty;

                                            //   if (isUserPurchased) {
                                            //     // ユーザーが購入済みの場合、アラートダイアログを表示する
                                            //     showDialog(
                                            //       context: context,
                                            //       builder: (BuildContext context) {
                                            //         return AlertDialog(
                                            //           title: Text('お知らせ'),
                                            //           content: Text('購入履歴の復元ができました。'),
                                            //           actions: [
                                            //             TextButton(
                                            //               onPressed: () async {
                                            //                 await Navigator.pushAndRemoveUntil(
                                            //                   context,
                                            //                   MaterialPageRoute(builder: (context) => MyApp()),
                                            //                   (_) => false,
                                            //                 );
                                            //               },
                                            //               child: Text('OK'),
                                            //             ),
                                            //           ],
                                            //         );
                                            //       },
                                            //     );
                                            //   } else {
                                            //     // ユーザーが未購入の場合、適切な処理を行う
                                            //     // ...
                                            //   }
                                            // } on PlatformException catch (e) {
                                            //   // Error restoring purchases
                                            // }
                                            final revenueCat = RevenueCat();
                                            await revenueCat.initRC();
                                            // リストアメッセージを表示
                                            await ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('リストアが完了しました😊'),
                                              ),
                                            );
                                            await Future.delayed(Duration(seconds: 1));
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('購入情報をリストアする'),
                                        ),
                                        SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '購入の確認・注意事項',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 16),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '利用規約・プライバシーポリシー\n',
                                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: 'プレミアムプランへの加入で、利用規約とプライバシーポリシーに同意いただいたとみなします。',
                                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '\n利用規約',
                                                      style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
                                                      recognizer: TapGestureRecognizer()
                                                        ..onTap = () {
                                                          _launchURL('https://kawasaki-create.com/youniyou-eula/');
                                                        },
                                                    ),
                                                    TextSpan(
                                                      text: ' と ',
                                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: 'プライバシーポリシー',
                                                      style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
                                                      recognizer: TapGestureRecognizer()
                                                        ..onTap = () {
                                                          _launchURL('https://kawasaki-create.com/youniyou-privacy/');
                                                        },
                                                    ),
                                                    TextSpan(
                                                      text: ' に同意いただいたとみなします。',
                                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                '自動継続課金\n'
                                                '契約期間は、期限が切れる24時間以内に自動更新の解除をされない場合、自動更新されます。',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(height: 16),
                                              if (Platform.isIOS)
                                                Text(
                                                  '解約方法\n'
                                                  '設定>iTunes StoreとApp Store>Apple ID >Apple IDを表示>サブスクリプションからキャンセルで解約できます。',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              if (Platform.isAndroid)
                                                Text(
                                                  '解約方法\n'
                                                  'Google Playストアアプリ>メニュー>アカウント>サブスクリプションからキャンセルで解約できます。',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              SizedBox(height: 16),
                                              Text(
                                                '契約期間の確認\n'
                                                '解約方法と同じ手順で契約期間の確認いただけます。',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                '解約・キャンセル\n'
                                                '解約は上記の方法以外では解約できません。また、キャンセルは翌月より反映されます。そのため、当月分のキャンセルは受け付けておりません。',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text('有料会員登録'),
                  ),
                if (isSubscribed == false)
                  SizedBox(
                    height: 50, // バナー広告の高さを固定する
                    child: AdWidget(
                      ad: AdmobHelper.getBannerAd()..load(),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: _bottomNavigationBarItems,
            currentIndex: selectedIndex,
            onTap: _onItemTapped,
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: _showTodoDialog,
                child: Icon(Icons.add),
              ),
              SizedBox(height: 40),
            ],
          )),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
