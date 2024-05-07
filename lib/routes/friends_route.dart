import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Friends extends HookConsumerWidget {
  const Friends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final _controller = useTextEditingController();
    final friends = useState([]);
    final iconColor = useState(Colors.blue);

    String name = _controller.text;

    // Firestoreからデータを取得するStream
    final Stream<QuerySnapshot> _friendsStream = FirebaseFirestore.instance.collection('friends').where('user_id', isEqualTo: user?.uid).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('友達'),
        backgroundColor: Colors.cyan[100],
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
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
                                  '友達追加',
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
                                        onChanged: (value) {
                                          name = value;
                                        },
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
                                        // データベースに追加
                                        await FirebaseFirestore.instance.collection('friends').add({'name': name, 'icon': iconColor.value.value, 'user_id': user?.uid});
                                        _controller.clear();
                                        Navigator.pop(context);
                                      },
                                      child: Text('追加'),
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
                        ));
                  });
            },
            iconSize: 30,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('友達がいません'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(data['icon']),
                  ),
                ),
                title: Text(data['name']),
                subtitle: Text(data['user_id']),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
