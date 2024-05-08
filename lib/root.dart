import 'package:flutter/material.dart';
import 'package:youniyou/routes/friends_route.dart';
import 'package:youniyou/routes/home_route.dart';
import 'package:youniyou/routes/settings_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youniyou/todo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);
final todoProvider = StateProvider<Todo>((ref) => Todo());

class RootWidgets extends HookConsumerWidget {
  const RootWidgets({super.key});

  static const _RootWidgetIcons = [
    Icons.calendar_today,
    Icons.people,
    Icons.settings,
  ];

  static const _RootWidgetItemNames = [
    'スケジュール',
    '友達',
    '設定',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final todo = ref.watch(todoProvider);
    final routes = [
      Home(),
      Friends(),
      SettingsRoute(),
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

    Future<void> _showTodoDialog() async {
      final user = FirebaseAuth.instance.currentUser;
      final friendsSnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).get();
      final friends = friendsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      String? selectedFriendId = todo.friendId;
      DateTime? startDateTime = todo.startDateTime;
      DateTime? endDateTime = todo.endDateTime;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('予定の追加'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text('対象者を選択：'),
                      DropdownButton<String>(
                        value: selectedFriendId,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedFriendId = newValue;
                          });
                          ref.read(todoProvider.notifier).state = todo.copyWith(friendId: newValue);
                        },
                        items: friends.map((friend) {
                          return DropdownMenuItem<String>(
                            value: friend['id'],
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(friend['icon']),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(friend['name']),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      SizedBox(height: 16),
                      Text('開始日時：'),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDateTime ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startDateTime ?? DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                startDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              });
                              ref.read(todoProvider.notifier).state = todo.copyWith(startDateTime: startDateTime);
                            }
                          }
                        },
                        child: Text(startDateTime != null ? '${startDateTime!.year}/${startDateTime!.month}/${startDateTime!.day} ${startDateTime!.hour}:${startDateTime!.minute}' : '開始日時を選択'),
                      ),
                      SizedBox(height: 16),
                      Text('終了日時：'),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime ?? startDateTime ?? DateTime.now(),
                            firstDate: startDateTime ?? DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime ?? startDateTime ?? DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                endDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              });
                              ref.read(todoProvider.notifier).state = todo.copyWith(endDateTime: endDateTime);
                            }
                          }
                        },
                        child: Text(endDateTime != null ? '${endDateTime!.year}/${endDateTime!.month}/${endDateTime!.day} ${endDateTime!.hour}:${endDateTime!.minute}' : '終了日時を選択'),
                      ),
                      SizedBox(height: 16),
                      Text('内容：'),
                      TextFormField(
                        initialValue: todo.description,
                        onChanged: (value) {
                          ref.read(todoProvider.notifier).state = todo.copyWith(description: value);
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('リセット'),
                    onPressed: () {
                      ref.read(todoProvider.notifier).state = Todo();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('登録'),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('todo').add(todo.toMap());
                      ref.read(todoProvider.notifier).state = Todo();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }

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
          onPressed: _showTodoDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
