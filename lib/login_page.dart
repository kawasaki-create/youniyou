import 'dart:ffi';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youniyou/main.dart';

import 'package:youniyou/root.dart';

final isLoginProvider = StateProvider<bool>((ref) => false);
final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final password1Provider = StateProvider<String>((ref) => '');
final nameProvider = StateProvider<String>((ref) => '');
final userProvider = StateProvider<User?>((ref) => null);
final anonymousUserProvider = StateProvider<User?>((ref) => null);

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  Future<Map<String, String>?> getLoginInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userEmail = prefs.getString('userEmail');
    String? loginProvider = prefs.getString('loginProvider');

    if (userId != null && userEmail != null && loginProvider != null) {
      return {
        'userId': userId,
        'userEmail': userEmail,
        'loginProvider': loginProvider,
      };
    }
    return null;
  }

  Future<void> saveLoginInfo(User user, String loginProvider) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('userEmail', user.email ?? '');
    await prefs.setString('loginProvider', loginProvider);
  }

  Future<void> _onSignInWithAnonymousUser(BuildContext context, WidgetRef ref) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    try {
      final UserCredential userCredential = await firebaseAuth.signInAnonymously();
      ref.read(anonymousUserProvider.notifier).state = userCredential.user;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const RootWidgets()), (route) => false);
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

  Future<void> appleSignInHook(BuildContext context, WidgetRef ref) async {
    try {
      print('AppSignInを実行');
      final rawNonce = generateNonce();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print('Apple Credential: $appleCredential');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      print('Firebase User Credential: $userCredential');

      ref.read(userProvider.notifier).state = userCredential.user;
      await saveLoginInfo(userCredential.user!, 'apple'); // ログイン情報を保存

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const RootWidgets()), (route) => false);
      }
    } catch (e) {
      print('Apple SignInエラー: $e');
      // エラーメッセージを表示する
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sign in with Appleエラー'),
          content: Text('Sign in with Appleに失敗しました。設定を確認してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      ref.read(userProvider.notifier).state = userCredential.user;
      await saveLoginInfo(userCredential.user!, 'google'); // ログイン情報を保存

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const RootWidgets()), (route) => false);
      }
    } catch (e) {
      print('Googleアカウントを使用したログインに失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogin = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: isLogin.value ? Text('ログイン') : Text('新規登録'),
        backgroundColor: Colors.cyan[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // isLogin.value ? Login() : Register(),
            // TextButton(
            //     onPressed: () {
            //       // ref.read(isLoginProvider.notifier).state = !isLogin;
            //       isLogin.value = !isLogin.value;
            //     },
            //     child: isLogin.value
            //         ? Text(
            //             '新規登録はこちら',
            //             style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
            //           )
            //         : Text(
            //             'ログインはこちら',
            //             style: TextStyle(decoration: TextDecoration.underline, color: Colors.redAccent),
            //           )),
            Text(''),
            if (Platform.isIOS)
              SignInButton(
                Buttons.apple,
                onPressed: () {
                  appleSignInHook(context, ref);
                  print('Appleログイン');
                },
              ),
            if (Platform.isAndroid)
              SignInButton(
                Buttons.google,
                onPressed: () async {
                  await signInWithGoogle(context, ref);
                },
              ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onSignInWithAnonymousUser(context, ref),
                child: Text('登録せず利用'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Login extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(emailProvider);
    final password = ref.watch(passwordProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// メールアドレス
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
          ),
          onChanged: (value) {
            ref.read(emailProvider.notifier).state = value;
          },
        ),

        /// パスワード
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
          obscureText: true,
          onChanged: (value) {
            ref.read(passwordProvider.notifier).state = value;
          },
        ),
        Text(''),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          // ログインボタン
          child: OutlinedButton(
            onPressed: () {
              print('ログイン');
            },
            child: const Text('ログイン'),
          ),
        ),
      ],
    );
  }
}

class Register extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(emailProvider);
    final password = ref.watch(passwordProvider);
    final password1 = ref.watch(password1Provider);
    final name = ref.watch(nameProvider);
    final errorTxt = useState('');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// メールアドレス
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
          ),
          onChanged: (value) {
            ref.read(emailProvider.notifier).state = value;
          },
        ),

        /// パスワード
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
          obscureText: true,
          onChanged: (value) {
            ref.read(passwordProvider.notifier).state = value;
          },
        ),

        /// パスワード確認
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード確認',
          ),
          obscureText: true,
          onChanged: (value) {
            ref.read(password1Provider.notifier).state = value;
          },
        ),
        Text(''),
        Text(errorTxt.value),
        Container(
          width: double.infinity,
          // ユーザー登録ボタン
          child: ElevatedButton(
            onPressed: () async {
              try {
                if (password == password1) {
                  // パスワードが一致した場合
                  final FirebaseAuth auth = FirebaseAuth.instance;
                  await auth.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                } else {
                  // パスワードが一致しない場合
                  print('パスワードが一致しません');
                }
              } catch (e) {
                errorTxt.value = e.toString();
                print('エラーが発生しました: $e');
              }
            },
            child: const Text('新規登録'),
          ),
        ),
      ],
    );
  }
}
