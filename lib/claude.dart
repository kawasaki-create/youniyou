import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:anthropic_dart/anthropic_dart.dart';
import 'env.dart'; // ここでenv.dartをインポート
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Claude extends HookConsumerWidget {
  final String friendId;

  const Claude({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = AnthropicService(Env.apiKey); // ここでAPIキーを使ってAnthropicServiceを作成
    final message = useState('');
    final response = useState('Claudeの答え');
    final textController = useTextEditingController(); // コントローラーを追加
    final isLoading = useState(false); // ローディング状態を追加

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chatbot'),
        backgroundColor: Colors.cyan[100],
      ),
      body: SingleChildScrollView(
        // 画面がスクロール可能になるように変更
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: textController, // コントローラーを適用
                decoration: InputDecoration(
                  labelText: 'メッセージを入力してください',
                ),
                onChanged: (value) {
                  message.value = value;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      isLoading.value = true; // ローディングを開始
                      await talk(message.value).then((value) {
                        response.value = value;
                        isLoading.value = false; // ローディングを終了
                      });
                      textController.clear(); // 入力値をクリア
                      message.value = ''; // 状態もリセット
                    },
                    child: Text('送信'),
                  ),
                  SizedBox(width: 8), // ボタン間のスペース
                  ElevatedButton(
                    onPressed: () {
                      textController.clear(); // 入力値をクリア
                      message.value = ''; // 状態もリセット
                    },
                    child: Text('リセット'),
                  ),
                ],
              ),
              Text(''),
              isLoading.value
                  ? CircularProgressIndicator() // ローディング中に表示
                  : SelectableText(response.value),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> talk(String text) async {
    const String model = "claude-3-haiku-20240307";
    final service = AnthropicService(Env.apiKey, model: model);
    var request = Request();
    request.model = model;
    request.maxTokens = 1024;
    request.messages = [
      Message(
        role: "user",
        content: text,
      )
    ];
    var response = await service.sendRequest(request: request);

    // debugPrint('Response body: ${response.toJson()["content"][0]["text"]}');

    return response.toJson()["content"][0]["text"];
  }

  Future _getPlan() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('todo').where('friendId', isEqualTo: friendId).get();

    final plans = querySnapshot.docs.map((doc) => doc.data()).toList();
    // 取得したデータを適切に処理します（例：表示、保存など）

    return plans;
  }
}
