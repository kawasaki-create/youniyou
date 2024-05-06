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

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anonymousUser = ref.watch(anonymousUserProvider);
    final user = FirebaseAuth.instance.currentUser;
    const snackBar = SnackBar(
      content: Text("ログアウトします"),
    );
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
                    });
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
                            // 内部で保持しているログイン情報等が初期化される
                            // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
                            await FirebaseAuth.instance.signOut();

                            // snackBarを表示し、非同期的に完了するまで待機
                            await ScaffoldMessenger.of(context).showSnackBar(snackBar);

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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text('スケジュール'),
            ),
            Text(user?.uid ?? '未ログイン'),
            Text(anonymousUser?.uid ?? ''),

            /// デバッグ用ボタン群
            // ElevatedButton(
            //   onPressed: anonymousUser != null ? () => _linkAccount(context, ref) : null,
            //   child: Text('アカウントリンク'),
            // ),
            // ElevatedButton(
            //   onPressed: user != null ? () => _unlinkGoogleAccount(context, ref) : null,
            //   child: Text('Googleアカウントの紐付けを解除'),
            // ),
            // ElevatedButton(
            //   onPressed: () async {
            //     await user?.delete();
            //     Navigator.of(context).pushReplacement(
            //       MaterialPageRoute(builder: (context) {
            //         return LoginPage();
            //       }),
            //     );
            //   },
            //   child: Text('アカウント削除'),
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
            //   },
            //   child: Text('最初の画面へ'),
            // )
          ],
        ),
      ),
    );
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
