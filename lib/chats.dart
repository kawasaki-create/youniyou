import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends HookConsumerWidget {
  final String friendId;
  final String friendName;

  const ChatScreen({Key? key, required this.friendId, required this.friendName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 友達とのトーク画面を実装
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
      ),
      body: Center(
        child: Text('友達とのトーク画面'),
      ),
    );
  }
}
