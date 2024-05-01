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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Login(),
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
}
