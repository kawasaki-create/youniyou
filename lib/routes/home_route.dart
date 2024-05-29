import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:youniyou/login_page.dart';
import 'package:youniyou/main.dart';
import 'package:youniyou/todo.dart';

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anonymousUser = ref.watch(anonymousUserProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final calendarFormat = useState(CalendarFormat.month);
    final focusedDay = useState(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('スケジュール'),
        backgroundColor: Colors.cyan[100],
        actions: [
          if (anonymousUser != null)
            IconButton(
              icon: Icon(Icons.link),
              iconSize: 30,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    if (Platform.isAndroid)
                      return AlertDialog(
                        title: Text('Googleアカウントでログインする'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: anonymousUser != null ? () => _linkAccount(context, ref) : null,
                              child: Text('アカウントリンク'),
                            ),
                          ],
                        ),
                      );
                    if (Platform.isIOS)
                      return CupertinoAlertDialog(
                        title: Text('Appleアカウントでログインする'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: anonymousUser != null ? () => _linkAccount(context, ref) : null,
                              child: Text('アカウントリンク'),
                            ),
                          ],
                        ),
                      );
                    return Container();
                  },
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.person_remove),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('アカウントを削除しますか？(戻せません)'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _deleteAccount(context, ref);
                        },
                        child: Text('削除'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('ログアウトしますか？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();

                            await ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("ログアウトします")),
                            );

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                                return MyApp();
                              }),
                            );
                          },
                          child: Text('ログアウト'),
                        ),
                      ],
                    );
                  });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('todo').where('id', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('予定がありません'));
          }

          final events = <DateTime, List<Meeting>>{};

          snapshot.data!.docs.forEach((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final id = doc.id;
            final startDateTime = (data['startDateTime'] as Timestamp).toDate();
            final endDateTime = (data['endDateTime'] as Timestamp).toDate();
            final eventName = data['description'] ?? '予定なし';
            final friendId = data['friendId'] as String? ?? '';

            final meeting = Meeting(
              id,
              eventName,
              startDateTime,
              endDateTime,
              Colors.blue,
              false,
              friendId,
            );

            // 予定を複数日にまたがるように調整
            for (DateTime d = startDateTime; d.isBefore(endDateTime) || d.isAtSameMomentAs(endDateTime); d = d.add(Duration(days: 1))) {
              final eventDate = DateTime.utc(d.year, d.month, d.day);
              if (events.containsKey(eventDate)) {
                events[eventDate]!.add(meeting);
              } else {
                events[eventDate] = [meeting];
              }
            }
          });

          return SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height, // 画面の縦の長さに合わせる
              child: TableCalendar(
                eventLoader: (day) {
                  return events[day] ?? [];
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dayEvents = events[day] ?? [];

                    // 予定が4つ以上ある場合は「全て表示」のみを表示
                    if (dayEvents.length > 2) {
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('予定一覧'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: dayEvents.map((event) {
                                              final meeting = event as Meeting;
                                              return ListTile(
                                                title: Text(meeting.eventName),
                                                subtitle: FutureBuilder<String?>(
                                                  future: _getFriendName(meeting.friendId),
                                                  builder: (context, snapshot) {
                                                    final friendName = snapshot.data ?? '不明';
                                                    return Text(
                                                      '開始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.from)}\n'
                                                      '終了: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.to)}\n'
                                                      '友達: $friendName',
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('閉じる'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '全表示',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // 予定が3つ以下の場合は通常通り予定を表示
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                        ...dayEvents.map((event) {
                          final meeting = event as Meeting;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 1.5),
                            decoration: BoxDecoration(
                              color: meeting.background,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                meeting.eventName,
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dayEvents = events[day] ?? [];
                    // 今日の日付のスタイルをdefaultBuilderと同じように設定
                    if (dayEvents.length > 1) {
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.red), // 赤い丸を追加
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(2.0),
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('予定一覧'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: dayEvents.map((event) {
                                              final meeting = event as Meeting;
                                              return ListTile(
                                                title: Text(meeting.eventName),
                                                subtitle: FutureBuilder<String?>(
                                                  future: _getFriendName(meeting.friendId),
                                                  builder: (context, snapshot) {
                                                    final friendName = snapshot.data ?? '不明';
                                                    return Text(
                                                      '開始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.from)}\n'
                                                      '終了: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.to)}\n'
                                                      '友達: $friendName',
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('閉じる'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '全表示',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // 予定が3つ以下の場合は通常通り予定を表示
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.red), // 赤い丸を追加
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(2.0),
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                        ),
                        ...dayEvents.map((event) {
                          final meeting = event as Meeting;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 1.5),
                            decoration: BoxDecoration(
                              color: meeting.background,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                meeting.eventName,
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                  markerBuilder: (context, day, events) => Container(), // 青い丸を表示しない
                ),
                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent, // 青い丸の背景を透明にする
                  ),
                  canMarkersOverflow: true,
                  cellMargin: EdgeInsets.all(4.0),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent, // 今日の日付の特別な装飾をなくす
                  ),
                  todayTextStyle: TextStyle(
                    color: Colors.black, // 今日の日付の文字色を通常に戻す
                  ),
                ),
                daysOfWeekHeight: 30.0,
                rowHeight: 80.0, // 基本の行の高さを少し増やす
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay.value,
                calendarFormat: calendarFormat.value,
                onFormatChanged: (format) {
                  calendarFormat.value = format;
                },
                onPageChanged: (newFocusedDay) {
                  focusedDay.value = newFocusedDay;
                },
                headerStyle: HeaderStyle(formatButtonVisible: true),
                onDaySelected: (selectedDay, newFocusedDay) {
                  focusedDay.value = newFocusedDay;
                  final selectedEvents = events[selectedDay] ?? [];
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('予定一覧'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: selectedEvents.map((meeting) {
                              return ListTile(
                                title: Text(meeting.eventName),
                                subtitle: FutureBuilder<String?>(
                                  future: _getFriendName(meeting.friendId),
                                  builder: (context, snapshot) {
                                    final friendName = snapshot.data ?? '不明';
                                    return Text(
                                      '開始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.from)}\n'
                                      '終了: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.to)}\n'
                                      '友達: $friendName',
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('閉じる'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getFriendName(String friendId) async {
    final friendDoc = await FirebaseFirestore.instance.collection('friends').doc(friendId).get();
    if (friendDoc.exists) {
      final data = friendDoc.data();
      return data?['name'];
    }
    return null;
  }

  Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final anonymousUser = ref.read(anonymousUserProvider);

    try {
      if (Platform.isIOS) {
        final rawNonce = generateNonce();
        final nonce = sha256ofString(rawNonce);
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );
        final UserCredential userCredential = await anonymousUser!.linkWithCredential(oauthCredential);
        ref.read(userProvider.notifier).state = userCredential.user;
        ref.read(anonymousUserProvider.notifier).state = null;
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('アカウントリンク成功'),
              content: Text('Appleアカウントとリンクされました。'),
            );
          },
        );
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await anonymousUser!.linkWithCredential(credential);
        ref.read(userProvider.notifier).state = userCredential.user;
        ref.read(anonymousUserProvider.notifier).state = null;
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('アカウントリンク成功'),
              content: Text('Googleアカウントとリンクされました。'),
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('エラー'),
              content: Text('このアカウントは既に別のアカウントに関連付けられています。\n'
                  '既存のアカウントでログインするか、別のアカウントを使用してください。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('エラー'),
              content: SelectableText(e.toString()),
            );
          },
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('エラー'),
            content: SelectableText(e.toString()),
          );
        },
      );
    }
  }

  Future<void> _unlinkGoogleAccount(BuildContext context, WidgetRef ref) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? user = firebaseAuth.currentUser;

    if (user != null) {
      try {
        await user.unlink(GoogleAuthProvider.PROVIDER_ID);
        ref.read(userProvider.notifier).state = null;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('紐付け解除成功'),
              content: Text('Googleアカウントの紐付けが解除されました。'),
            );
          },
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'no-such-provider') {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('エラー'),
                content: Text('このアカウントはGoogleアカウントと紐付けられていません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('エラー'),
                content: Text(e.toString()),
              );
            },
          );
        }
      } catch (e) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('エラー'),
              content: Text(e.toString()),
            );
          },
        );
      }
    }
  }

  Future<void> deleteAllFriends(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: userId).get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteAllTodo(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('todo').where('id', isEqualTo: userId).get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? user = firebaseAuth.currentUser;

    if (user != null) {
      try {
        // アカウント削除前に friends コレクションの関連ドキュメントを削除
        await deleteAllFriends(user.uid);
        // アカウント削除前に todo コレクションの関連ドキュメントを削除
        await deleteAllTodo(user.uid);
        await FirebaseFirestore.instance.collection('chats').doc(user.uid).delete();
        await user.delete();
        ref.read(userProvider.notifier).state = null;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('アカウント削除成功'),
              content: Text('アカウントが削除されました。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MyApp()),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } on FirebaseAuthException catch (e) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('エラー'),
              content: Text(e.toString()),
            );
          },
        );
      } catch (e) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('エラー'),
              content: Text(e.toString()),
            );
          },
        );
      }
    }
  }

  String generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class Meeting {
  Meeting(this.id, this.eventName, this.from, this.to, this.background, this.isAllDay, this.friendId);

  final String id;
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String friendId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Meeting && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
