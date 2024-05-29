import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:anthropic_dart/anthropic_dart.dart';
import 'package:intl/intl.dart';
import 'env.dart'; // ここでenv.dartをインポート
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Claude extends HookConsumerWidget {
  final String friendId;
  final String friendName;

  const Claude({super.key, required this.friendId, required this.friendName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = AnthropicService(Env.apiKey); // ここでAPIキーを使ってAnthropicServiceを作成
    final message = useState('');
    final response = useState('');
    final textController = useTextEditingController(); // コントローラーを追加
    final isLoading = useState(false); // ローディング状態を追加
    final isChatting = useState(false); // チャット画面のフラグ
    final analysisResult = useState(''); //分析結果

    // チャット画面のウィジェット
    Widget chatScreen() {
      return Scaffold(
        appBar: AppBar(
          title: Text(friendName + ' のAIチャット'),
          backgroundColor: Colors.cyan[100],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // TextFormField(
                //   controller: textController, // コントローラーを適用
                //   decoration: InputDecoration(
                //     labelText: 'メッセージを入力してください',
                //   ),
                //   onChanged: (value) {
                //     message.value = value;
                //   },
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     ElevatedButton(
                //       onPressed: () {
                //         isLoading.value = true; // ローディングを開始
                //         talk(message.value).then((value) {
                //           response.value = value;
                //           isLoading.value = false; // ローディングを終了
                //         });
                //       },
                //       child: Text('送信'),
                //     ),
                //     SizedBox(width: 8), // ボタン間のスペース
                //     ElevatedButton(
                //       onPressed: () {
                //         textController.clear(); // 入力値をクリア
                //         message.value = ''; // 状態もリセット
                //       },
                //       child: Text('リセット'),
                //     ),
                //   ],
                // ),
                isLoading.value
                    ? CircularProgressIndicator() // ローディング中に表示
                    : SelectableText(response.value),
                // Text('分析結果：'),
                SelectableText(analysisResult.value),
                Text(''),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('前の画面に戻る'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 現在の画面
    Widget mainScreen() {
      return Scaffold(
        appBar: AppBar(
          title: Text(friendName + ' のAI分析'),
          backgroundColor: Colors.cyan[100],
        ),
        body: SingleChildScrollView(
          // 画面がスクロール可能になるように変更
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.35), // 上部にスペースを追加
                ElevatedButton(
                  onPressed: () async {
                    isLoading.value = true; // ローディングを開始
                    final plans = await _getPlan();
                    final chats = await _getChat();

                    final analyzePrompt = plans.map((plan) => '予定名: ${plan['description']}, 開始日時: ${plan['startFormattedDate']}, 終了日時: ${plan['endFormattedDate']}').join('\n') + '\n\n' + chats.join('\n');

                    final analysis = await talk('以下のは、作成者と${friendName}が共に行う予定と、作成者が${friendName}に対して思っていることのメモである。これを見て分かることを分析しなさい。また、楽しそう・つまらなそうなど思ったことも指摘しなさい。さらに、タイトルやメモの内容からどんなことが推測できるかも言及すること。' + analyzePrompt);

                    analysisResult.value = analysis;
                    isLoading.value = false; // ローディングを終了

                    isChatting.value = true; // チャット画面に切り替え
                  },
                  child: Text('分析スタート'),
                ),
                SizedBox(height: 20), // ボタンとローディングインジケータの間にスペースを追加
                isLoading.value
                    ? CircularProgressIndicator() // ローディング中に表示
                    : SelectableText(response.value),
              ],
            ),
          ),
        ),
      );
    }

    return isChatting.value ? chatScreen() : mainScreen();
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

  Future<List<Map<String, dynamic>>> _getPlan() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('todo').where('friendId', isEqualTo: friendId).get();

    final plans = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final startTimestamp = data['startDateTime'] as Timestamp;
      final endTimestamp = data['endDateTime'] as Timestamp;
      final startFormattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(startTimestamp.toDate());
      final endFormattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(endTimestamp.toDate());
      data['startFormattedDate'] = startFormattedDate;
      data['endFormattedDate'] = endFormattedDate;
      return data;
    }).toList();

    return plans;
  }

  Future _getChat() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('chats').doc(friendId).collection('messages').get();

    final chats = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp;
      final formattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(timestamp.toDate());
      data['formattedDate'] = formattedDate;
      return data['text'] ?? '';
    }).toList();

    return chats;
  }
}
