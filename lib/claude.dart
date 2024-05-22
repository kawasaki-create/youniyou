import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:claude_dart_flutter/claude_dart_flutter.dart';
import 'env.dart'; // ここでenv.dartをインポート

class Claude extends HookConsumerWidget {
  final String friendId;

  const Claude({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final service = AnthropicService(apiKey: Env.apiKey); // ここでAPIキーを使ってAnthropicServiceを作成

    return Scaffold(
        appBar: AppBar(
          title: Text('AI Chatbot'),
          backgroundColor: Colors.cyan[100],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(friendId),
              Text(
                'クロード',
                style: TextStyle(fontSize: 24),
              ),
              Text(
                'APIキー: ${Env.apiKey}', // ここでAPIキーを表示
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ));
  }
}
