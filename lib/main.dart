import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_example_topics_flutter/pages/init_sdk_page.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

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
      home: HomePage(title: 'ZegoExpressExample'),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {

    print(ZegoConfig.instance); // Load config instance

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              ListTile(
                title: Text('Publish Stream'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                    return InitPage(true);
                  }));
                },
              ),
              ListTile(
                title: Text('Play Stream'),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                    return InitPage(true);
                  }));
                },
              )
            ]
          ).toList(),
        )
      )
    );
  }
}


