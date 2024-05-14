import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:youniyou/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:youniyou/main.dart';
import 'package:crypto/crypto.dart';
import 'package:youniyou/todo.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:youniyou/plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final todoProvider = StateProvider<Todo>((ref) => Todo());

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anonymousUser = ref.watch(anonymousUserProvider);
    final user = FirebaseAuth.instance.currentUser;
    final events = useState<List<Meeting>>([]);
    final isLoading = useState(true);

    useEffect(() {
      Future.microtask(() async {
        final loadedEvents = await _getAllEvents(user!.uid);
        events.value = loadedEvents;
        isLoading.value = false;
      });
      return null;
    }, [user]);

    if (isLoading.value) {
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
                            // ログアウト処理
                            await FirebaseAuth.instance.signOut();

                            // snackBarを表示し、非同期的に完了するまで待機
                            await ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("ログアウトします")),
                            );

                            // ログイン画面に遷移＋チャット画面を破棄
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
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: MeetingDataSource(events.value),
        monthViewSettings: MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
        appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
          final Meeting meeting = details.appointments.first;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Plan(friendId: meeting.friendId, selectedDate: meeting.from),
                ),
              );
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meeting.background,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<Meeting>> _getAllEvents(String uid) async {
    final snapshot = await FirebaseFirestore.instance.collection('todo').where('id', isEqualTo: uid).get();
    final events = <Meeting>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startDateTime = data['startDateTime'] != null ? (data['startDateTime'] as Timestamp).toDate() : null;
      final endDateTime = data['endDateTime'] != null ? (data['endDateTime'] as Timestamp).toDate() : null;
      final eventName = data['description'];
      final friendId = data['friendId'] as String?;

      if (startDateTime != null && endDateTime != null && friendId != null) {
        final friendData = await _getFriendData(friendId);
        events.add(Meeting(
          eventName ?? '予定なし',
          startDateTime,
          endDateTime,
          Color(friendData?['icon'] ?? 0xFF0000FF),
          false,
          friendId,
        ));
      }
    }

    return events;
  }

  Future<Map<String, dynamic>?> _getFriendData(String friendId) async {
    final friendDoc = await FirebaseFirestore.instance.collection('friends').doc(friendId).get();
    if (friendDoc.exists) {
      return friendDoc.data();
    }
    return null;
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

  Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final anonymousUser = ref.read(anonymousUserProvider);

    try {
      if (Platform.isIOS) {
        // iOS (Appleアカウント)の場合
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
        // Android (Googleアカウント)の場合
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
