import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Claude extends HookConsumerWidget {
  final String friendId;

  const Claude({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ],
          ),
        ));
  }
}
