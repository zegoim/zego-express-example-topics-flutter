//
//  home_page.dart
//  zego-express-example-topics-flutter
//
//  Created by Patrick Fu on 2020/11/12.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors/sensors.dart';

import 'package:zego_express_example_topics_flutter/home/global_setting_page.dart';
import 'package:zego_express_example_topics_flutter/topics/AudioAdvanced/audio_effect_player/audio_effect_player_page.dart';
import 'package:zego_express_example_topics_flutter/topics/AudioAdvanced/soundlevel_spectrum/soundlevel_spectrum_page.dart';
import 'package:zego_express_example_topics_flutter/topics/AudioAdvanced/voice_change/voice_change_page.dart';
import 'package:zego_express_example_topics_flutter/topics/BestPractices/video_talk/video_talk_page.dart';
import 'package:zego_express_example_topics_flutter/topics/CommonFunctions/common_video_config/common_video_config_page.dart';
import 'package:zego_express_example_topics_flutter/topics/CommonFunctions/room_message/room_message_page.dart';
import 'package:zego_express_example_topics_flutter/topics/CommonFunctions/video_rotation/video_rotation.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/beauty_watermark_snapshot/beauty_watermark_snapshot_page.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/media_player/media_player_resource_selection_page.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/multiple_rooms/multiple_rooms_page.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/stream_mixing/mixer_main.dart';
import 'package:zego_express_example_topics_flutter/topics/QuickStart/play_stream/play_stream_login_page.dart';
import 'package:zego_express_example_topics_flutter/topics/QuickStart/publish_stream/publish_stream_login_page.dart';
import 'package:zego_express_example_topics_flutter/topics/QuickStart/quick_start/quick_start_page.dart';
import 'package:zego_express_example_topics_flutter/topics/StreamAdvanced/stream_by_cdn/stream_by_cdn.dart';
import 'package:zego_express_example_topics_flutter/topics/StreamAdvanced/stream_monitoring/stream_monitoring.dart';
import 'package:zego_express_example_topics_flutter/topics/VideoAdvanced/encoding_and_decoding/encoding_and_decoding_page.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isShow = false;
  int count = 0;

  @override
  void initState() {
    super.initState();

    // 限制屏幕垂直方向
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Load config
    ZegoConfig.instance.init();
    Permission.camera.request().then((value) async{ 
      await Permission.microphone.request();

      accelerometerEvents.listen((event) async {
        int value = 20;
        if (event.x.abs() > value ||
            event.y.abs() > value ||
            event.z.abs() > value) {
          count ++;
          if (!_isShow && count >= 3) {
            _isShow = true;
            await showDialog<bool>(
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: OutlinedButton(onPressed: ZegoUtils.shareLog, child: Text('上传日志'), autofocus:true),
                  );
                },
                context: context,
                barrierDismissible: true);
            _isShow = false;
            count = 0;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZegoExpressExample'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                return GlobalSettingPage();
              }));
            }
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              ListTile(title: Text('快速开始'), tileColor: Colors.grey[300],),
              TopicWidget('Quick Start', QuickStartPage(), context),
              TopicWidget('Publish Stream', PublishStreamLoginPage(), context),
              TopicWidget('Play Stream', PlayStreamLoginPage(), context),
              
              ListTile(title: Text('最佳实践'), tileColor: Colors.grey[300],),
              TopicWidget('VideoTalk', VideoTalkPage(), context),
              
              ListTile(title: Text('常用功能'), tileColor: Colors.grey[300],),
              TopicWidget('Common Video Config', CommonVideoConfigPage(), context),
              TopicWidget('Video Rotation', ChooseVideoRotationPage(), context),
              TopicWidget('RoomMessage', RoomMessagePage(), context),             

              ListTile(title: Text('推流、拉流进阶'), tileColor: Colors.grey[300],),
              TopicWidget('Stream Monitorning', StreamMonitoringPage(), context),
              TopicWidget('Stream by CDN', AddStreamToCDNPage(), context),

              ListTile(title: Text('视频进阶功能'), tileColor: Colors.grey[300],),
              TopicWidget('Video Encoding and Decoding', EncodingAndDecodingPage(), context),
              
              ListTile(title: Text('音频进阶功能'), tileColor: Colors.grey[300],),
              TopicWidget('Voice Change', VoiceChangePage(), context),
              TopicWidget('Soundlevel And Spectrum', SoundlevelSpectrumPage(), context),
              TopicWidget('Audio Effect Player', AudioEffectPlayerPage(), context),

              ListTile(title: Text('其他功能'), tileColor: Colors.grey[300],),
              TopicWidget('Beauty Watermark Snapshot', BeautyWatermarkSnapshotPage(), context),
              TopicWidget('Stream Mixer', MixerMainPage(), context),
              TopicWidget('Media Player', MediaPlayerResourceSelectionPage(), context),
              TopicWidget('Login Multiple Room', MutilpeRoomsPage(), context),   
            ]
          ).toList(),
        )
      )
    );
  }
}


class TopicWidget extends ListTile {

  TopicWidget(
    String title,
    Widget targetPage,
    BuildContext context
  ) : super(
    title: Text(title),
    trailing: Icon(Icons.keyboard_arrow_right),
    onTap: () {
      if (ZegoConfig.instance.appID > 0 && ZegoConfig.instance.appSign.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
          return targetPage;
        }));
      } else {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Tips'),
            content: Text('Please set up AppID and other necessary configuration first'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                    return GlobalSettingPage();
                  }));
                },
              )
            ],
          );
        });
      }
    },
  );
}