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
import 'package:syncfusion_flutter_calendar/calendar.dart';
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
            print('エラーが発生しました: ${snapshot.error}');
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('予定がありません'));
          }

          final uniqueEvents = <String, Meeting>{};
          final eventsByDate = <DateTime, List<Meeting>>{};
          final events = snapshot.data!.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final startDateTime = data['startDateTime'] != null ? (data['startDateTime'] as Timestamp).toDate() : DateTime.now();
            final endDateTime = data['endDateTime'] != null ? (data['endDateTime'] as Timestamp).toDate() : DateTime.now();
            final eventName = data['description'] ?? '予定なし';
            final friendId = data['friendId'] as String? ?? '';
            final friendData = await _getFriendData(friendId);
            final friendName = friendData?['name'] ?? '友達';

            final eventKey = '$eventName|$startDateTime|$endDateTime';
            if (!uniqueEvents.containsKey(eventKey)) {
              uniqueEvents[eventKey] = Meeting(
                eventName,
                startDateTime,
                endDateTime,
                Colors.blue,
                false,
                friendName,
              );
            }

            final date = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
            eventsByDate.putIfAbsent(date, () => []).add(uniqueEvents[eventKey]!);

            return uniqueEvents[eventKey]!;
          }).toList();

          return FutureBuilder<List<Meeting>>(
            future: Future.wait(events),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }

              final events = snapshot.data ?? [];
              final dataSource = MeetingDataSource(events);

              return SfCalendar(
                view: CalendarView.month,
                dataSource: dataSource,
                monthViewSettings: MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                ),
                appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                  final date = DateTime(details.date.year, details.date.month, details.date.day);
                  final dailyEvents = eventsByDate[date] ?? [];

                  if (dailyEvents.length > 3) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('予定一覧'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dailyEvents.map((meeting) {
                                    return ListTile(
                                      title: Text(meeting.eventName),
                                      subtitle: Text(
                                        '開始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.from)}\n'
                                        '終了: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.to)}\n'
                                        '友達: ${meeting.friendId}',
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
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '全て表示',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Column(
                      children: dailyEvents.map((meeting) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(meeting.eventName),
                                  content: Text(
                                    '開始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.from)}\n'
                                    '終了: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meeting.to)}\n'
                                    '友達: ${meeting.friendId}',
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
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: meeting.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meeting.eventName,
                              style: TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getFriendData(String friendId) async {
    final friendDoc = await FirebaseFirestore.instance.collection('friends').doc(friendId).get();
    if (friendDoc.exists) {
      return friendDoc.data();
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
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay, this.friendId);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String friendId;
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}
