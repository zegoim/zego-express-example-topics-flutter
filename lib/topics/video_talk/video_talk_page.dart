//
//  video_talk_page.dart
//  zego-express-example-topics-flutter
//
//  Created by Patrick Fu on 2020/11/16.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/topics/video_talk/video_talk_view_object.dart';

class VideoTalkPage extends StatefulWidget {
  @override
  _VideoTalkPageState createState() => _VideoTalkPageState();
}

class _VideoTalkPageState extends State<VideoTalkPage> {

  final String roomID = 'VideoTalkRoom-1';

  final String streamID = 's-${ZegoConfig.instance.userID}';

  ZegoRoomState roomState = ZegoRoomState.Disconnected;

  List<VideoTalkViewObject> viewObjectList = List();

  VideoTalkViewObject _localUserViewObject;

  @override
  void initState() {
    super.initState();

    setRoomEventCallback();

    joinTalkRoom();
  }

  @override
  void dispose() {
    exitTalkRoom();

    super.dispose();
  }

  // MARK: TalkRoom Methods

  Future<void> joinTalkRoom() async {

    // Create ZegoExpressEngine
    print("🚀 Create ZegoExpressEngine");
    await ZegoExpressEngine.createEngine(ZegoConfig.instance.appID, ZegoConfig.instance.appSign, ZegoConfig.instance.isTestEnv, ZegoScenario.Communication, enablePlatformView: true);

    // Login Room
    print("🚪 Login room, roomID: $roomID");
    await ZegoExpressEngine.instance.loginRoom(roomID, ZegoUser(ZegoConfig.instance.userID, ZegoConfig.instance.userName));

    // Set the publish video configuration
    print("⚙️ Set video config: 540p preset");
    await ZegoExpressEngine.instance.setVideoConfig(ZegoVideoConfig.preset(ZegoVideoConfigPreset.Preset540P));

    // Start Preview
    print("🔌 Start preview");
    _localUserViewObject = VideoTalkViewObject(true, this.streamID);
    _localUserViewObject.init(() {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas.view(_localUserViewObject.viewID));
    });

    setState(() {
      viewObjectList.add(_localUserViewObject);
    });

    // Start Publish
    print("📤 Start publishing stream, streamID: $streamID");
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> exitTalkRoom() async {
    print("📤 Stop publishing stream");
    await ZegoExpressEngine.instance.stopPublishingStream();

    print("🔌 Stop preview");
    await ZegoExpressEngine.instance.stopPreview();

    // It is recommended to logout room when stopping the video call.
    print("🚪 Logout room, roomID: $roomID");
    await ZegoExpressEngine.instance.logoutRoom(roomID);

    // And you can destroy the engine when there is no need to call.
    print("🏳️ Destroy ZegoExpressEngine");
    await ZegoExpressEngine.destroyEngine();
  }

  // MARK: - ViewObject Methods

  /// Add a view of user who has entered the room and play the user stream
  void addRemoteViewObjectWithStreamID(String streamID) {
    VideoTalkViewObject viewObject = VideoTalkViewObject(false, streamID);

    viewObject.init(() {

      ZegoCanvas playCanvas = ZegoCanvas.view(viewObject.viewID);
      playCanvas.viewMode = ZegoViewMode.AspectFill;

      print('📥 Start playing stream, streamID: $streamID');
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: playCanvas);

    });

    setState(() {
      viewObjectList.add(viewObject);
    });
  }

  void removeViewObjectWithStreamID(String streamID) {
    print('📥 Stop playing stream, streamID: $streamID');
    ZegoExpressEngine.instance.stopPlayingStream(streamID);

    for (VideoTalkViewObject viewObject in viewObjectList) {
      if (viewObject.streamID == streamID) {
        viewObject.uninit();

        setState(() {
          viewObjectList.remove(viewObject);
        });
      }
    }
  }

  // MARK: - Zego Event

  void setRoomEventCallback() {

    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      print("🚩 🚪 Room state update, state: $state, errorCode: $errorCode, roomID: $roomID");
      setState(() {
        roomState = state;
      });
    };

    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      print("🚩 🌊 Room stream update, type: $updateType, streamsCount: ${streamList.length}, roomID: $roomID");

      List allStreamIDList = viewObjectList.map((e) => e.streamID).toList();

      if (updateType == ZegoUpdateType.Add) {

        for (ZegoStream stream in streamList) {
          print("🚩 🌊 --- [Add] StreamID: ${stream.streamID}, UserID: ${stream.user.userID}");

          if (!allStreamIDList.contains(stream.streamID)) {
            addRemoteViewObjectWithStreamID(stream.streamID);
          }
        }

      } else if (updateType == ZegoUpdateType.Delete) {

        for (ZegoStream stream in streamList) {
          print("🚩 🌊 --- [Delete] StreamID: ${stream.streamID}, UserID: ${stream.user.userID}");

          removeViewObjectWithStreamID(stream.streamID);
        }
      }
    };
  }

  // MARK: Widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("VideoTalk"),
      ),
      body: SafeArea(
        child: mainContent(),
      ),
    );
  }

  Widget mainContent() {
    return Column(
      children: [
        Container(
          child: roomInfoWidget(),
          padding: EdgeInsets.all(5.0),
        ),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 5.0,
              crossAxisSpacing: 5.0,
              childAspectRatio: 3.0/4.0,
            ),
            children: viewObjectList.map((e) => e.view).toList(),
            padding: EdgeInsets.all(5.0),
          ),
        ),
      ],
    );
  }

  Widget roomInfoWidget() {
    return Row(
      children: [
        Text("RoomID: $roomID"),
        Spacer(),
        Text(roomStateDesc()),
      ],
    );
  }

  String roomStateDesc() {
    switch (roomState) {
      case ZegoRoomState.Disconnected:
        return "Disconnected 🔴";
        break;
      case ZegoRoomState.Connecting:
        return "Connecting 🟡";
        break;
      case ZegoRoomState.Connected:
        return "Connected 🟢";
        break;
      default:
        return "Unknown";
    }
  }
}