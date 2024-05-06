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

    String name = _controller.text;
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
                  isScrollControlled: true, // 画面半分よりも大きなモーダルの表示設定
                  builder: (BuildContext context) {
                    return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Container(
                          height: 300,
                          child: Center(
                            child: Column(
                              // mainAxisAlignment: MainAxisAlignment.center,
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
                                        color: Colors.blue,
                                      ),
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
                                        await FirebaseFirestore.instance.collection('friends').add({'name': name, 'icon': '友達のアイコン', 'user_id': user?.uid});
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text('友達'),
            ),
            Text(user?.uid ?? '未ログイン'),
          ],
        ),
      ),
    );
  }
}
