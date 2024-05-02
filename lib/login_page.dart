import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = false;
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';
  String password1 = '';
  String passwordV = '';
  String name = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
        backgroundColor: Colors.cyan[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isLogin ? Login() : Register(),
            TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: isLogin
                    ? Text(
                        '新規登録はこちら',
                        style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                      )
                    : Text(
                        'ログインはこちら',
                        style: TextStyle(decoration: TextDecoration.underline, color: Colors.redAccent),
                      )),
          ],
        ),
      ),
    );
  }

  Widget Login() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// メールアドレス
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
          ),
          onChanged: (value) {
            setState(() {
              email = value;
            });
          },
        ),

        /// パスワード
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
          obscureText: true,
          onChanged: (value) {
            setState(() {
              password = value;
            });
          },
        ),
      ],
    );
  }

  Widget Register() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// メールアドレス
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
          ),
          onChanged: (value) {
            setState(() {
              email = value;
            });
          },
        ),

        /// パスワード
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
          obscureText: true,
          onChanged: (value) {
            setState(() {
              password = value;
            });
          },
        ),

        /// パスワード確認
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'パスワード確認',
          ),
          obscureText: true,
          onChanged: (value) {
            setState(() {
              password1 = value;
            });
          },
        ),

        /// ユーザー名
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'ユーザー名',
          ),
          onChanged: (value) {
            setState(() {
              name = value;
            });
          },
        ),
        Text(''),
        Container(
          width: double.infinity,
          // ユーザー登録ボタン
          child: ElevatedButton(
            onPressed: () {
              if (passwordV == password1) {
                // パスワードが一致した場合
                print('登録完了');
                setState(() {
                  password = password1;
                });
              } else {
                // パスワードが一致しない場合
                print('パスワードが一致しません');
              }
            },
            child: const Text('新規登録'),
          ),
        )
      ],
    );
  }
}
