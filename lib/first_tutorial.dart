import 'package:flutter/material.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:youniyou/main.dart';

class IntroView extends StatelessWidget {
  const IntroView({super.key});

  static final pages = [
    PageViewModel(
      pageColor: const Color(0xFFFF7A00),
      body: Text('＋ボタンを押し、友達を追加します。アイコンタップで編集もできます。'),
      title: Text('友達の追加'),
      mainImage: Image.asset(
        'assets/images/intro_view/SliceAddPlan.png',
        // height: 400.0,
        // width: 400.0,
        // alignment: Alignment.center,
        fit: BoxFit.contain,
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xD2FF0000),
      // iconImageAssetPath: 'assets/images/intro_view/Slice2.png',
      body: Text(
        '友達との予定を追加します。一覧では編集も可能です。',
      ),
      title: Text('予定の追加'),
      mainImage: Image.asset(
        'assets/images/intro_view/SliceAddDetail1.png',
        // height: 320.0,
        // width: 320.0,
        // alignment: Alignment.center,
        fit: BoxFit.contain,
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    ),
    PageViewModel(
      pageColor: Color.fromARGB(210, 228, 0, 171),
      // iconImageAssetPath: 'assets/images/intro_view/Slice2.png',
      body: Text(
        '何もないところをタップで、友達に後で何か伝えたいことのメモをLINEのように追加できます。',
      ),
      title: Text('メモ画面'),
      mainImage: Image.asset(
        'assets/images/intro_view/SliceAddDetail2.png',
        // height: 320.0,
        // width: 320.0,
        // alignment: Alignment.center,
        fit: BoxFit.contain,
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xFF7A008B),
      // iconImageAssetPath: 'assets/images/intro_view/Slice3.png',
      body: Text(
        '友達全体との予定の確認ができます。日付タップで詳細も見れます。',
      ),
      title: Text('カレンダー画面'),
      mainImage: Image.asset(
        'assets/images/intro_view/SliceAddBl.png',
        // height: 400.0,
        // width: 400.0,
        // alignment: Alignment.center,
        fit: BoxFit.contain,
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xBC0044FF),
      // iconImageAssetPath: 'assets/images/intro_view/Slice4.png',
      body: Text(
        '友達との予定やメモを参考にAIがどんな関係かを診断してくれます。',
      ),
      title: Text('AI診断(β版)'),
      mainImage: Image.asset(
        'assets/images/intro_view/SliceHome.png',
        // height: 400.0,
        // width: 400.0,
        // alignment: Alignment.center,
        fit: BoxFit.contain,
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    ),
    PageViewModel(
      pageColor: Colors.greenAccent,
      mainImage: Center(
        child: Text(
          'さっそく始めましょう！',
          style: TextStyle(fontFamily: 'Noto Sans JP', fontSize: 50, color: Colors.white),
        ),
      ),
      titleTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroViewsFlutter(
        pages,
        showNextButton: true,
        showBackButton: true,
        onTapDoneButton: () {
          // Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          );
        },
        pageButtonTextStyles: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
        ),
      ),
    );
  }
}
