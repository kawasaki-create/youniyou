import 'package:flutter/material.dart';
import 'package:youniyou/routes/friends_route.dart';
import 'package:youniyou/routes/home_route.dart';
import 'package:youniyou/routes/settings_route.dart';

class RootWidgets extends StatefulWidget {
  const RootWidgets({super.key});

  @override
  State<RootWidgets> createState() => _RootWidgetsState();
}

class _RootWidgetsState extends State<RootWidgets> {
  @override
  int _selectedIndex = 0;
  var _bottomNavigationBarItems = <BottomNavigationBarItem>[];

  // アイコン情報
  static const _RootWidgetIcons = [
    Icons.calendar_today,
    Icons.people,
    Icons.settings,
  ];

  // アイコン文字列
  static const _RootWidgetItemNames = [
    'スケジュール',
    '友達',
    '設定',
  ];

  late var _routes = [
    Home(),
    Friends(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0; // 初期値を設定
    // ボトムナビゲーションバーのアイテムを更新
    _bottomNavigationBarItems = List.generate(
      _RootWidgetItemNames.length,
      (index) => index == _selectedIndex ? _UpdateActiveState(index) : _UpdateDeactiveState(index),
    );
  }

  /// インデックスのアイテムをアクティベートする
  BottomNavigationBarItem _UpdateActiveState(int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        _RootWidgetIcons[index],
        color: Colors.black87,
      ),
      label: _RootWidgetItemNames[index],
    );
  }

  /// インデックスのアイテムをディアクティベートする
  BottomNavigationBarItem _UpdateDeactiveState(int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        _RootWidgetIcons[index],
        color: Colors.black26,
      ),
      label: _RootWidgetItemNames[index],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _bottomNavigationBarItems[_selectedIndex] = _UpdateDeactiveState(_selectedIndex);
      _bottomNavigationBarItems[index] = _UpdateActiveState(index);
      _selectedIndex = index;

      // 友達一覧のインデックスを1に設定
      if (index == 1) {
        _selectedIndex = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _routes.elementAt(_selectedIndex),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: _bottomNavigationBarItems,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // ここに処理を追加
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
