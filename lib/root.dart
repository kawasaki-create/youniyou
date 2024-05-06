import 'package:flutter/material.dart';
import 'package:youniyou/routes/friends_route.dart';
import 'package:youniyou/routes/home_route.dart';
import 'package:youniyou/routes/settings_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class RootWidgets extends HookConsumerWidget {
  const RootWidgets({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final routes = [
      Home(),
      Friends(),
      Settings(),
    ];

    void _onItemTapped(int index) {
      ref.read(selectedIndexProvider.notifier).state = index;
    }

    List<BottomNavigationBarItem> _bottomNavigationBarItems = List.generate(
      _RootWidgetItemNames.length,
      (index) => BottomNavigationBarItem(
        icon: Icon(
          _RootWidgetIcons[index],
          color: index == selectedIndex ? Colors.black87 : Colors.black26,
        ),
        label: _RootWidgetItemNames[index],
      ),
    );

    return ScaffoldMessenger(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: routes[selectedIndex],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: _bottomNavigationBarItems,
          currentIndex: selectedIndex,
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
