//
//  home_page.dart
//  zego-express-example-topics-flutter
//
//  Created by Patrick Fu on 2020/11/12.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_example_topics_flutter/topics/play_stream/play_stream_init_page.dart';
import 'package:zego_express_example_topics_flutter/topics/publish_stream/publish_stream_init_page.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    // Load config
    ZegoConfig.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZegoExpressExample'),
      ),
      body: SafeArea(
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              TopicWidget('Publish Stream', PublishStreamInitPage(), context),
              TopicWidget('Play Stream', PlayStreamInitPage(), context),
            ]
          ).toList(),
        )
      )
    );
  }
}


class TopicWidget extends ListTile {

  Widget targetPage;
  BuildContext context;

  TopicWidget(
    String title,
    Widget targetPage,
    BuildContext context
  ) : super(
    title: Text(title),
    trailing: Icon(Icons.keyboard_arrow_right),
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
        return targetPage;
      }));
    },
  );
}