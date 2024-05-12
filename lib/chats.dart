import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends HookConsumerWidget {
  final String friendId;
  final String friendName;

  const ChatScreen({Key? key, required this.friendId, required this.friendName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final messageController = useTextEditingController();
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final messages = snapshot.data?.docs ?? [];

                WidgetsBinding.instance?.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data()! as Map<String, dynamic>;
                    final isCurrentUser = data['userId'] == user?.uid;

                    if (data.containsKey('imageUrl')) {
                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: Image.network(data['imageUrl']),
                        ),
                      );
                    } else {
                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(data['text']),
                        ),
                      );
                    }
                  },
                );
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
                ElevatedButton(
                  onPressed: () async {
                    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedImage != null) {
                      // 画像が選択された場合の処理
                      final imageFile = File(pickedImage.path);
                      final storageRef = FirebaseStorage.instance.ref().child('chats/$friendId/${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await storageRef.putFile(imageFile);
                      final imageUrl = await storageRef.getDownloadURL();
                      FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').add({
                        'imageUrl': imageUrl,
                        'userId': user?.uid,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }
                  },
                  child: Text('画像を選択'),
                ),
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
                        scrollController.jumpTo(scrollController.position.maxScrollExtent);
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
}
