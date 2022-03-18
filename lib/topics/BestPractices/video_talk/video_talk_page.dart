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
import 'package:zego_express_example_topics_flutter/topics/BestPractices/video_talk/video_talk_view_object.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class VideoTalkPage extends StatefulWidget {
  @override
  _VideoTalkPageState createState() => _VideoTalkPageState();
}

class _VideoTalkPageState extends State<VideoTalkPage> {

  final String _roomID = 'VideoTalkRoom-1';

  final String _streamID = 's-${ZegoConfig.instance.userID}';

  ZegoRoomState _roomState = ZegoRoomState.Disconnected;

  List<VideoTalkViewObject> _viewObjectList = [];

  late VideoTalkViewObject _localUserViewObject;

  bool _isEnableCamera = true;
  set isEnableCamera(bool value) {
    setState(() => _isEnableCamera = value);
    ZegoExpressEngine.instance.enableCamera(value);
  }

  bool _isEnableMic = true;
  set isEnableMic(bool value) {
    setState(() => _isEnableMic = value);
    ZegoExpressEngine.instance.muteMicrophone(!value);
  }

  bool _isEnableSpeaker = true;
  set isEnableSpeaker(bool value) {
    setState(() => _isEnableSpeaker = value);
    ZegoExpressEngine.instance.muteSpeaker(!value);
  }

  @override
  void initState() {
    super.initState();

    setZegoEventCallback();

    joinTalkRoom();
  }

  @override
  void dispose() {
    exitTalkRoom();

    clearZegoEventCallback();

    super.dispose();
  }

  // MARK: TalkRoom Methods

  Future<void> joinTalkRoom() async {

    // Create ZegoExpressEngine
    print("🚀 Create ZegoExpressEngine");
    ZegoEngineProfile profile = ZegoEngineProfile(
      ZegoConfig.instance.appID, 
      ZegoScenario.Communication,
      enablePlatformView: true);
    await ZegoExpressEngine.createEngineWithProfile(profile);

    // Login Room
    print("🚪 Login room, roomID: $_roomID");
    await ZegoExpressEngine.instance.loginRoom(_roomID, ZegoUser(ZegoConfig.instance.userID, ZegoConfig.instance.userName), config: ZegoRoomConfig(0, true, ZegoConfig.instance.token));

    // Set the publish video configuration
    print("⚙️ Set video config: 540p preset");
    await ZegoExpressEngine.instance.setVideoConfig(ZegoVideoConfig.preset(ZegoVideoConfigPreset.Preset540P));

    // Start Preview
    print("🔌 Start preview");
    _localUserViewObject = VideoTalkViewObject(true, this._streamID);
    _localUserViewObject.init(() {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas.view(_localUserViewObject.viewID));
    });

    setState(() {
      _viewObjectList.add(_localUserViewObject);
    });

    // Start Publish
    print("📤 Start publishing stream, streamID: $_streamID");
    await ZegoExpressEngine.instance.startPublishingStream(_streamID);
  }

  Future<void> exitTalkRoom() async {
    print("📤 Stop publishing stream");
    await ZegoExpressEngine.instance.stopPublishingStream();

    print("🔌 Stop preview");
    await ZegoExpressEngine.instance.stopPreview();

    // It is recommended to logout room when stopping the video call.
    print("🚪 Logout room, roomID: $_roomID");
    await ZegoExpressEngine.instance.logoutRoom(_roomID);

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
      _viewObjectList.add(viewObject);
    });
  }

  void removeViewObjectWithStreamID(String streamID) {
    print('📥 Stop playing stream, streamID: $streamID');
    ZegoExpressEngine.instance.stopPlayingStream(streamID);

    for (VideoTalkViewObject viewObject in _viewObjectList) {
      if (viewObject.streamID == streamID) {
        viewObject.uninit();

        setState(() {
          _viewObjectList.remove(viewObject);
        });
      }
    }
  }

  // MARK: - Zego Event

  void setZegoEventCallback() {

    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      print("🚩 🚪 Room state update, state: $state, errorCode: $errorCode, roomID: $roomID");
      setState(() {
        _roomState = state;
      });
    };

    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      print("🚩 🌊 Room stream update, type: $updateType, streamsCount: ${streamList.length}, roomID: $roomID");

      List allStreamIDList = _viewObjectList.map((e) => e.streamID).toList();

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

  void clearZegoEventCallback() {
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
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
            children: _viewObjectList.map((e) => e.view!).toList(),
            padding: EdgeInsets.all(5.0),
          ),
        ),
        togglesWidget(),
      ],
    );
  }

  Widget togglesWidget() {
    return Row(children: [
      Column(children: [
        Text('Camera'),
        Switch(value: _isEnableCamera, onChanged: (value) => isEnableCamera = value),
      ]),
      Column(children: [
        Text('Microphone'),
        Switch(value: _isEnableMic, onChanged: (value) => isEnableMic = value),
      ]),
      Column(children: [
        Text('Speaker'),
        Switch(value: _isEnableSpeaker, onChanged: (value) => isEnableSpeaker = value),
      ]),
    ], mainAxisAlignment: MainAxisAlignment.spaceEvenly);
  }

  Widget roomInfoWidget() {
    return Row(children: [
      Text("RoomID: $_roomID"),
      Spacer(),
      Text(roomStateDesc()),
    ]);
  }

  String roomStateDesc() {
    switch (_roomState) {
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