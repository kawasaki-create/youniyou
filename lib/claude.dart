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
    final planDebug = useState('しょきち'); //デバッグ用、後で削除
    final planAnalysis = useState(''); //予定分析結果
    final chatDebug = useState('チャット'); //デバッグ用、後で削除
    final chatAnalysis = useState(''); //チャット分析結果

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
              //       onPressed: () async {
              //         isLoading.value = true; // ローディングを開始
              //         await talk(message.value).then((value) {
              //           response.value = value;
              //           isLoading.value = false; // ローディングを終了
              //         });
              //         textController.clear(); // 入力値をクリア
              //         message.value = ''; // 状態もリセット
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
              ElevatedButton(
                onPressed: () async {
                  final plans = await _getPlan();
                  planDebug.value = plans.toString();
                  final analyzePrompt = plans.map((plan) => '予定名: ${plan['description']}, 開始日時: ${plan['startFormattedDate']}, 終了日時: ${plan['endFormattedDate']}').join('\n');
                  // print('以下のは友人との予定である。これを見て分かることを分析しなさい。' + analyzePrompt);
                  isLoading.value = true; // ローディングを開始
                  await talk('以下のは友人との予定である。これを見て分かることを分析しなさい。また、予定について楽しそう・つまらなそうなど思ったことも指摘しなさい。さらに、タイトルからどんな予定なのかも予測して言及すること。' + analyzePrompt).then((value) {
                    planAnalysis.value = value;
                    isLoading.value = false; // ローディングを終了
                  });
                },
                child: Text('予定分析'),
              ),
              Text('分析結果：'),
              SelectableText(planAnalysis.value),
              Text(''),
              ElevatedButton(
                onPressed: () async {
                  final chats = await _getChat();
                  chatDebug.value = chats.toString();
                  final analyzePrompt = chats.join('\n');
                  isLoading.value = true; // ローディングを開始
                  await talk('以下のは友人に対するメモである。これを見て分かることを分析しなさい。また、このメモにからわかる、友人との関係、楽しそう・つまらなそうなど思ったことも指摘しなさい。' + analyzePrompt).then((value) {
                    chatAnalysis.value = value;
                    isLoading.value = false; // ローディングを終了
                  });
                },
                child: Text('メモ分析'),
              ),
              Text('分析結果：'),
              SelectableText(chatAnalysis.value),
              Text(''),
              isLoading.value
                  ? CircularProgressIndicator() // ローディング中に表示
                  : SelectableText(response.value),
              // ElevatedButton(
              //   onPressed: () async {
              //     final plans = await _getPlan();
              //     planDebug.value = plans.toString();
              //     debugPrint(plans.toString());
              //   },
              //   child: Text('予定を取得'),
              // ),
              // // SelectableText(planDebug.value),
              // Text('友人の名前: ${friendName}'),
              // ElevatedButton(
              //   onPressed: () async {
              //     final chats = await _getChat();
              //     chatDebug.value = chats.toString();
              //     // debugPrint(chats.toString());
              //   },
              //   child: Text('チャットを取得'),
              // ),
              // SelectableText(chatDebug.value),
              ElevatedButton(
                onPressed: () {
                  // ここで予定とメモを分析して、AIとのチャットフラグも変更して分析チャットをスタートする予定
                },
                child: Text('分析スタート'),
              ),
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
