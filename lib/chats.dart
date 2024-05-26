import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends HookConsumerWidget {
  final String friendId;
  final String friendName;

  const ChatScreen({Key? key, required this.friendId, required this.friendName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final messageController = useTextEditingController();
    final scrollController = useScrollController();

    // Firestoreからデータを取得するStream
    final _messagesStream = useMemoized(() {
      return FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').orderBy('timestamp').snapshots();
    }, [friendId]);

    final snapshot = useStream(_messagesStream);

    void _deleteMessage(String messageId) {
      FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').doc(messageId).delete();
    }

    void _showDeleteDialog(String messageId, bool isImage) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('削除'),
            content: Text(isImage ? '画像を削除しますか？' : 'メモを削除しますか？'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  _deleteMessage(messageId);
                  Navigator.of(context).pop();
                },
                child: Text('削除'),
              ),
            ],
          );
        },
      );
    }

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    final messages = snapshot.data?.docs ?? [];
    DateTime? previousDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        backgroundColor: Colors.cyan[100],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final data = message.data()! as Map<String, dynamic>;
                final isCurrentUser = data['userId'] == user?.uid;
                final timestamp = data['timestamp'] as Timestamp?;
                final messageDate = timestamp?.toDate();

                final isNewDate = messageDate?.day != previousDate?.day;
                final dateWidget = messageDate == null
                    ? SizedBox.shrink()
                    : isNewDate
                        ? Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${messageDate.month}/${messageDate.day}(${_getWeekday(messageDate.weekday)})',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        : SizedBox.shrink();

                previousDate = messageDate;
                if (data.containsKey('imageUrl')) {
                  return Column(
                    children: [
                      dateWidget,
                      GestureDetector(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('画像を削除'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _showDeleteDialog(message.id, true);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageDate != null ? DateFormat('HH:mm').format(messageDate) : '',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Image.network(data['imageUrl']),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      dateWidget,
                      GestureDetector(
                        onLongPress: () {
                          _showDeleteDialog(message.id, false);
                        },
                        child: Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  messageDate != null ? DateFormat('HH:mm').format(messageDate) : '',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(width: 8),
                                Flexible(child: Text(data['text'])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'メモを入力',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // 有料版作成までは画像の送信は無効化
                // IconButton(
                //   onPressed: () async {
                //     final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                //     if (pickedImage != null) {
                //       // 画像が選択された場合の処理
                //       final imageFile = File(pickedImage.path);
                //       final storageRef = FirebaseStorage.instance.ref().child('chats/$friendId/${DateTime.now().millisecondsSinceEpoch}.jpg');
                //       await storageRef.putFile(imageFile);
                //       final imageUrl = await storageRef.getDownloadURL();
                //       FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').add({
                //         'imageUrl': imageUrl,
                //         'userId': user?.uid,
                //         'timestamp': FieldValue.serverTimestamp(),
                //       }).then((_) {
                //         // ここでスクロールを最下部に移動させる
                //         scrollController.animateTo(
                //           scrollController.position.maxScrollExtent,
                //           duration: Duration(milliseconds: 300),
                //           curve: Curves.easeOut,
                //         );
                //       });
                //     }
                //   },
                //   icon: Icon(Icons.photo),
                // ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').add({
                        'text': messageController.text,
                        'userId': user?.uid,
                        'timestamp': FieldValue.serverTimestamp(),
                      }).then((_) {
                        messageController.clear();
                        // ここでスクロールを最下部に移動させる
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });
                    }
                  },
                  child: Text('送信'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '月';
      case DateTime.tuesday:
        return '火';
      case DateTime.wednesday:
        return '水';
      case DateTime.thursday:
        return '木';
      case DateTime.friday:
        return '金';
      case DateTime.saturday:
        return '土';
      case DateTime.sunday:
        return '日';
      default:
        return '';
    }
  }
}
