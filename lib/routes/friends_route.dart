import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youniyou/chats.dart';
import 'package:youniyou/main.dart';
import 'package:youniyou/plan.dart';
import 'package:youniyou/claude.dart';

class FriendModal extends HookConsumerWidget {
  final String? friendId;
  final String? friendName;
  final int? friendIcon;

  const FriendModal({
    Key? key,
    this.friendId,
    this.friendName,
    this.friendIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final _controller = useTextEditingController(text: friendName ?? '');
    final iconColor = useState(friendIcon != null ? Color(friendIcon!) : Colors.blue);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 300,
        child: Center(
          child: Column(
            children: <Widget>[
              Text(''),
              Text(
                friendId != null ? '友達編集' : '友達追加',
                style: TextStyle(fontSize: 25, decoration: TextDecoration.underline),
              ),
              Spacer(),
              Row(
                children: [
                  Text('友達のアイコン: '),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.value,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('アイコンの色を選択'),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.blue),
                                    onTap: () {
                                      iconColor.value = Colors.blue;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.red),
                                    onTap: () {
                                      iconColor.value = Colors.red;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.yellow),
                                    onTap: () {
                                      iconColor.value = Colors.yellow;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.green),
                                    onTap: () {
                                      iconColor.value = Colors.green;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.orange),
                                    onTap: () {
                                      iconColor.value = Colors.orange;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.pink),
                                    onTap: () {
                                      iconColor.value = Colors.pink;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text('選択'),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('友達の名前: '),
                  Container(
                    width: 200,
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: '名前を入力',
                      ),
                      controller: _controller,
                    ),
                  )
                ],
              ),
              Text(''),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (friendId != null) {
                        // 友達情報を更新
                        await FirebaseFirestore.instance.collection('friends').doc(friendId).update({
                          'name': _controller.text,
                          'icon': iconColor.value.value,
                        });
                      } else {
                        // 新しい友達を追加
                        await FirebaseFirestore.instance.collection('friends').add({
                          'name': _controller.text,
                          'icon': iconColor.value.value,
                          'user_id': user?.uid,
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: Text(friendId != null ? '編集' : '追加'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('閉じる'),
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class Friends extends HookConsumerWidget {
  const Friends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isSubscribed = ref.watch(subscriptionProvider);
    final isBan = useState(false);
    final isBanAdd = useState(false);

    Future _subscsribeOffDialog() async {
      final friendsSnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).get();
      final friends = friendsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      if (friends.length >= 6 && !isSubscribed) {
        isBan.value = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('友達数制限'),
              content: Text('無料会員の場合、友達は最大5人までです。機能を利用する場合、友達を削除するか有料会員になると制限が解除されます。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      } else {
        isBan.value = false;
      }
    }

    Future _subscsribeOffAddDialog() async {
      final friendsSnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).get();
      final friends = friendsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      if (friends.length >= 5 && !isSubscribed) {
        isBanAdd.value = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('友達の追加制限'),
              content: Text('無料会員の場合、友達の追加は最大5人までです。これ以上友達を増やす場合、有料会員になると制限が解除されます。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      } else {
        isBanAdd.value = false;
      }
    }

    // Firestoreからデータを取得するStream
    final _friendsStream = useMemoized(() {
      return user != null ? FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user.uid).snapshots() : const Stream.empty();
    }, [user?.uid]);

    final snapshot = useStream(_friendsStream);

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return FriendModal();
              },
            );
          },
          child: Text('友達を追加'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('友達'),
        backgroundColor: Colors.cyan[100],
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_rounded),
            onPressed: () async {
              // 友達の数を取得して制限をチェック
              await _subscsribeOffAddDialog();
              if (isBanAdd.value) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return FriendModal();
                },
              );
            },
            iconSize: 30,
          ),
        ],
      ),
      body: ListView(
        children: snapshot.data!.docs
            .map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return GestureDetector(
                onTap: () async {
                  // トーク画面に遷移
                  await _subscsribeOffDialog();
                  if (isBan.value) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friendId: document.id, friendName: data['name']),
                    ),
                  );
                },
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () async {
                      // 友達編集モーダルを表示
                      await _subscsribeOffDialog();
                      if (isBan.value) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return FriendModal(
                            friendId: document.id,
                            friendName: data['name'],
                            friendIcon: data['icon'],
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(data['icon']),
                      ),
                    ),
                  ),
                  title: Text(data['name']),
                  subtitle: Container(
                    width: MediaQuery.of(context).size.width * 0.6, // 幅を調整
                    child: FutureBuilder(
                      future: FirebaseFirestore.instance.collection('chats').doc(document.id).collection('messages').orderBy('timestamp', descending: true).limit(1).get().then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data != null) {
                            Map<String, dynamic> messageData = snapshot.data!.data()! as Map<String, dynamic>;
                            if (messageData.containsKey('imageUrl')) {
                              return Text('画像を送信しました');
                            } else {
                              String text = messageData['text'] ?? '';
                              List<String> lines = text.split('\n');
                              String displayText = lines.isNotEmpty ? lines.first : '';
                              if (displayText.length > 5) {
                                displayText = displayText.substring(0, 5) + '...';
                              }
                              return Text(displayText);
                            }
                          } else {
                            return Text('トークを始めましょう');
                          }
                        } else {
                          return Text('...');
                        }
                      },
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          // クロード画面に遷移
                          await _subscsribeOffDialog();
                          if (isBan.value) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Claude(friendId: document.id, friendName: data['name']),
                            ),
                          );
                        },
                        icon: Icon(Icons.psychology_outlined),
                      ),
                      TextButton(
                        onPressed: () async {
                          // 予定一覧画面に遷移
                          await _subscsribeOffDialog();
                          if (isBan.value) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Plan(friendId: document.id),
                            ),
                          );
                        },
                        child: Text('予定一覧'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('友達の削除'),
                                content: Text('本当に削除しますか？もどせません'),
                                actions: [
                                  TextButton(
                                    child: Text('キャンセル'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () {
                                      // 友達を削除
                                      FirebaseFirestore.instance.collection('friends').doc(document.id).delete();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            })
            .cast<Widget>()
            .toList(),
      ),
    );
  }
}
