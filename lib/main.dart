import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_example_topics_flutter/home/home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZegoExpressExample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
