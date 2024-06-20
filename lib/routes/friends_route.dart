import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youniyou/chats.dart';
import 'package:youniyou/invite_ai.dart';
import 'package:youniyou/main.dart';
import 'package:youniyou/plan.dart';
import 'package:youniyou/claude.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:youniyou/reviewHelper.dart';

class FriendModal extends HookConsumerWidget {
  final String? friendId;
  final String? friendName;
  final int? friendIcon;
  final bool isSubscribed;
  final String? friendImageUrl; // 追加

  const FriendModal({
    Key? key,
    this.friendId,
    this.friendName,
    this.friendIcon,
    this.isSubscribed = false,
    this.friendImageUrl, // 追加
  }) : super(key: key);

  void _showReviewDialog(BuildContext parentContext) {
    showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('このアプリには満足していただいてますか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("よろしければ感想をお聞かせください🙏"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    child: Text('不満🤔'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // ダイアログが閉じた後にスナックバーを表示
                      Future.delayed(Duration.zero, () {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('ありがとうございます。良いアプリになるよう努めます。'),
                          ),
                        );
                      });
                    },
                  ),
                  TextButton(
                    child: Text('満足😊✨'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      DrawerHelper.launchStoreReview(parentContext);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final _controller = useTextEditingController(text: friendName ?? '');
    final iconColor = useState(friendIcon != null ? Color(friendIcon!) : Colors.blue);
    final imageUrl = useState<String?>(friendImageUrl); // 初期値を設定

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance.ref().child('friend_icons/${user?.uid}/${friendId ?? DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrl.value = downloadUrl;
      }
    }

    void _showSubscriptionDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('有料会員専用機能'),
            content: Text('有料会員のみ友達のアイコンに画像を指定できます。'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    void _showReviewDialogWrapper() {
      _showReviewDialog(context);
    }

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
                      image: imageUrl.value != null && isSubscribed
                          ? DecorationImage(
                              image: NetworkImage(imageUrl.value!),
                              fit: BoxFit.cover,
                            )
                          : null,
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
                                      imageUrl.value = null; // 色選択時に画像をクリア
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.red),
                                    onTap: () {
                                      iconColor.value = Colors.red;
                                      imageUrl.value = null; // 色選択時に画像をクリア
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.yellow),
                                    onTap: () {
                                      iconColor.value = Colors.yellow;
                                      imageUrl.value = null; // 色選択時に画像をクリア
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.green),
                                    onTap: () {
                                      iconColor.value = Colors.green;
                                      imageUrl.value = null; // 色選択時に画像をクリア
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.orange),
                                    onTap: () {
                                      iconColor.value = Colors.orange;
                                      imageUrl.value = null; // 色選択時に画像をクリア
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  GestureDetector(
                                    child: CircleAvatar(backgroundColor: Colors.pink),
                                    onTap: () {
                                      iconColor.value = Colors.pink;
                                      imageUrl.value = null; // 色選択時に画像をクリア
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
                    child: Text('色アイコン'),
                  ),
                  ElevatedButton(
                    onPressed: isSubscribed ? _pickImage : _showSubscriptionDialog, // 有料会員のみ画像を選択できる
                    child: Text('画像アイコン'),
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
                          'image_url': imageUrl.value, // 画像URLを保存
                        });
                      } else {
                        // 新しい友達を追加
                        await FirebaseFirestore.instance.collection('friends').add({
                          'name': _controller.text,
                          'icon': iconColor.value.value,
                          'image_url': imageUrl.value, // 画像URLを保存
                          'user_id': user?.uid,
                        });

                        // 友達の数をチェックして2人目の場合にレビューを表示
                        final friendsSnapshot = await FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).get();
                        if (friendsSnapshot.docs.length == 2) {
                          Navigator.pop(context);
                          _showReviewDialogWrapper(); // モーダルを閉じた後にレビューを表示
                          return; // ここで処理を終了
                        }
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
                return FriendModal(isSubscribed: isSubscribed); // 有料会員情報を渡す
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
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteAi(),
                ),
              );
            },
            child: Text('おさそいAIチャット'),
          ),
          Text(' '),
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
                  return FriendModal(isSubscribed: isSubscribed); // 有料会員情報を渡す
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
                            isSubscribed: isSubscribed, // 有料会員情報を渡す
                            friendImageUrl: data['image_url'], // 追加
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
                        image: data['image_url'] != null && isSubscribed
                            ? DecorationImage(
                                image: NetworkImage(data['image_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
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
                            barrierDismissible: false,
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
                                    onPressed: () async {
                                      // 友達に紐づくメモを削除
                                      await FirebaseFirestore.instance.collection('chats').doc(document.id).delete();
                                      // 友達に紐づく予定を削除
                                      final todoQuerySnapshot = await FirebaseFirestore.instance.collection('todo').where('friendId', isEqualTo: document.id).get();
                                      for (var doc in todoQuerySnapshot.docs) {
                                        await doc.reference.delete();
                                      }
                                      // 画像を削除
                                      final imageUrl = data['image_url'];
                                      if (imageUrl != null) {
                                        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
                                        await storageRef.delete();
                                      }
                                      // chatsディレクトリ内の関連ディレクトリを削除
                                      final chatsRef = FirebaseStorage.instance.ref().child('chats/${document.id}');
                                      final ListResult listResult = await chatsRef.listAll();
                                      for (var item in listResult.items) {
                                        await item.delete();
                                      }
                                      for (var prefix in listResult.prefixes) {
                                        await prefix.delete();
                                      }
                                      // 友達を削除
                                      await FirebaseFirestore.instance.collection('friends').doc(document.id).delete();
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
