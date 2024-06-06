import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youniyou/feature/util/shared_preferences/shared_preferences_repository.dart';
import 'package:youniyou/firebase_options.dart';
import 'package:youniyou/root.dart';
import 'package:youniyou/login_page.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youniyou/first_tutorial.dart';

import 'common_widget/update_prompt_dialog.dart';
import 'emun/update_request_type.dart';
import 'feature/util/forced_update/update_request_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admobHelper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.configure(PurchasesConfiguration("appl_hfFalSoPmwPUewcYATNwVWuwmcN"));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AdmobHelper.initialization();

  // SharedPreferencesの初期化
  late final SharedPreferences sharedPreferences;
  await Future.wait([
    Future(() async {
      sharedPreferences = await SharedPreferences.getInstance();
    }),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesRepositoryProvider.overrideWithValue(
          SharedPreferencesRepository(sharedPreferences),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateStream = useMemoized(() => FirebaseAuth.instance.authStateChanges());
    final authStateChanges = useStream(authStateStream);
    return FutureBuilder<bool>(
      future: _isFirstLaunch(),
      builder: (context, snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return MaterialApp(
        //     home: Scaffold(
        //       body: Center(child: CircularProgressIndicator()),
        //     ),
        //   );
        // }

        if (snapshot.data == true) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              fontFamily: "Noto Sans JP",
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            home: IntroView(),
          );
        } else {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              fontFamily: "Noto Sans JP",
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            home: authStateChanges.data == null ? LoginPage() : RootWidgets(),
          );
        }
      },
    );
  }

  Future<bool> _isFirstLaunch() async {
    // デバッグで初回起動を確認するためにコメントアウト

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isAlreadyFirstLaunch') ?? true;
    if (isFirstLaunch) {
      prefs.setBool('isAlreadyFirstLaunch', false);
    }
    return isFirstLaunch;
    // // return true;
    // return false;
  }
}

class MyHomePage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.purple,
            ],
          ),
        ),
        child: Column(
          children: [
            Spacer(),
            Center(
              child: Text(
                'Youに用！',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '友達との予定にフォーカスした予定管理ができるシンプルなアプリ',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.greenAccent,
                    decorationThickness: 3.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    '使ってみる',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 150),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
