import 'package:flutter/material.dart';

class RootWidgets extends StatefulWidget {
  const RootWidgets({super.key});

  @override
  State<RootWidgets> createState() => _RootWidgetsState();
}

class _RootWidgetsState extends State<RootWidgets> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youに用！'),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Youに用！',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      )),
    );
  }
}
