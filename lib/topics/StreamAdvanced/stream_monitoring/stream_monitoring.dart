import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class StreamMonitoringPage extends StatefulWidget {
  const StreamMonitoringPage({Key? key }) : super(key: key);
  @override
  _StreamMonitoringPageState createState() => _StreamMonitoringPageState();
}

class _StreamMonitoringPageState extends State<StreamMonitoringPage> {

  late ZegoRoomState _roomState;
  final String _roomID = "stream_info";
  final String _streamID = "stream_info";
  static const double viewRatio = 3.0/4.0;

  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  late int _preViewWidth;
  late int _preViewHeight;
  late int _playViewWidth;
  late int _playViewHeight;

  late double _preVideoSendBitrate;
  late double _playVideoSendBitrate;

  late double _preFPS;
  late double _playFPS;

  late int _preRTT;
  late int _playRTT;

  late int _playDelay;

  late double _prePacketLoss;
  late double _playPacketLoss;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  late TextEditingController _publishStreamIDController;
  late TextEditingController _playStreamIDController;

  late ZegoDelegate _zegoDelegate;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();
    
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;
    _roomState = ZegoRoomState.Disconnected;

    _preViewWidth = 360;
    _preViewHeight = 640;
    _playViewWidth = 360;
    _playViewHeight = 640;

    _preVideoSendBitrate = 0;
    _playVideoSendBitrate = 0;

    _preFPS = 0;
    _playFPS = 0;

    _preRTT = 0;
    _playRTT = 0;

    _playDelay = 0;

    _prePacketLoss =0;
    _playPacketLoss = 0;

    _publishStreamIDController = TextEditingController();
    _publishStreamIDController.text = _streamID;

    _playStreamIDController = TextEditingController();
    _playStreamIDController.text = _streamID;

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate:onRoomStateUpdate, 
        onPublisherStateUpdate:onPublisherStateUpdate, 
        onPlayerStateUpdate:onPlayerStateUpdate,
        onPlayerQualityUpdate: onPlayerQualityUpdate,
        onPublisherQualityUpdate: onPublisherQualityUpdate,
        );
    _zegoDelegate.createEngine(enablePlatformView: true).then((value) {
      _zegoDelegate.loginRoom(_roomID);
    });

  }

  @override
  void dispose() {

    _zegoDelegate.logoutRoom(_roomID);

    _zegoDelegate.clearZegoEventCallback();

    _zegoDelegate.destroyEngine();

    _zegoDelegate.dispose();

    print('🏳️ Destroy ZegoExpressEngine');
    super.dispose();
  }

  void onRoomStateUpdate(String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
    setState(() => _roomState = state);
  }
  void onPublisherStateUpdate(String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
    setState(() => _publisherState = state);
  }
  void onPlayerStateUpdate(String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData) {
    setState(() => _playerState = state);
  }

  void onPublisherQualityUpdate(String streamID, ZegoPublishStreamQuality quality){
    setState(() {
      _preFPS = quality.videoSendFPS;
      _prePacketLoss = quality.packetLostRate;
      _preRTT = quality.rtt;
      _preVideoSendBitrate = quality.videoSendBytes;
    });
  }
  void onPlayerQualityUpdate(String streamID, ZegoPlayStreamQuality quality){
    setState(() {
      _playFPS = quality.videoRecvFPS;
      _playPacketLoss = quality.packetLostRate;
      _playRTT = quality.rtt;
      _playVideoSendBitrate = quality.videoRecvBytes;
      _playDelay = quality.delay;
    });
  }

  void onPublishStreamBtnPress() {
    if (_publisherState != ZegoPublisherState.Publishing && _publishStreamIDController.text.isNotEmpty)
    {
      _zegoDelegate.startPublishing(_publishStreamIDController.text, enablePlatformView: true).then((widget){
        setState(() {
          _previewViewWidget = widget;
        });
      });
    }
    else{
      _zegoDelegate.stopPublishing();
    }
  }

  void onPlayStreamBtnPress() {
    if (_playerState != ZegoPlayerState.Playing && _playStreamIDController.text.isNotEmpty)
    {
      _zegoDelegate.startPlaying(_playStreamIDController.text, enablePlatformView: true).then((widget) {
        setState(() {
          _playViewWidget = widget;
        });
      });
    }
    else{
      _zegoDelegate.stopPlaying(_playStreamIDController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stream Monitorning"),),
      body: SafeArea(child: 
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              roomInfoWidget(context),
              streamViewsWidget(),
              // roomIDWidget(context),
            ],
          ),
        )
      ),
    );
  }

  Widget roomInfoWidget(context) {
    return Padding(padding: EdgeInsets.only(left: 10), 
      child:  
        Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}')
    );
  }

  Widget roomIDWidget(context) {
    return Padding(padding: EdgeInsets.only(left: 10,right: 10),child:  Row(
      children: [
        Text('Publish StreamID:', style: TextStyle(fontSize: 11),),
        SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child:TextField(
              controller: _publishStreamIDController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            )),
        Expanded(child: Container()),
        Text('play StreamID:', style: TextStyle(fontSize: 11)),
        SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child:TextField(
              controller: _playStreamIDController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            ))
      ],
    ));
  }

  // Buttons and titles on the preview widget
  Widget preWidgetTopWidget() {
    return Padding(padding: EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('Local Preview View', 
            style: TextStyle(color: Colors.white))),
        Text('Resolution: $_preViewWidth x $_preViewHeight', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Video Send Bitrate: ${(_preVideoSendBitrate/1000).toStringAsFixed(2)}kbps', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Video Send FPS: ${_preFPS.toStringAsFixed(2)}f/s', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('RTT: ${_preRTT}ms', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Packet Loss: ${_prePacketLoss.toStringAsFixed(2)}%', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Expanded(child: Container()),
        Center(child:CupertinoButton.filled(
          child: Text(
            _publisherState == ZegoPublisherState.Publishing ? '✅ StopPublishing' : 'StartPublishing', 
            style: TextStyle(fontSize: 14.0),),
          onPressed: onPublishStreamBtnPress,
          padding: EdgeInsets.all(10.0)),
        )
      ]
    ));
  }

  // Buttons and titles on the play widget
  Widget playWidgetTopWidget() {
    return Padding(padding: EdgeInsets.only(bottom: 10),child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child:Text('Remote Play View', 
            style: TextStyle(color: Colors.white))),
        Text('Resolution: $_playViewWidth x $_playViewHeight', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Video Send Bitrate: ${(_playVideoSendBitrate/1000).toStringAsFixed(2)}kbps', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Video Send FPS: ${_playFPS.toStringAsFixed(2)}f/s', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('RTT: ${_playRTT}ms', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Delay: ${_playDelay}ms', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Text('Packet Loss: ${_playPacketLoss.toStringAsFixed(2)}%', style: TextStyle(color: Colors.red[100], fontSize: 11.5)),
        Expanded(child: Container()),
        Center(child:CupertinoButton.filled(
          child: Text(_playerState == ZegoPlayerState.Playing ? '✅ StopPlaying' : 'StartPlaying', 
            style: TextStyle(fontSize: 14.0),),
          onPressed: onPlayStreamBtnPress,
          padding: EdgeInsets.all(10.0)),
        )
      ]
    ));
  }

  Widget streamViewsWidget() {
    return Container(
      height: MediaQuery.of(context).size.height *0.5,
      child:GridView(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: viewRatio,
        ),
        children: [
          Stack(
            children: [
              Container(
                color: Colors.grey,
                child: _previewViewWidget,
              ),
            preWidgetTopWidget()
            ], 
            alignment: AlignmentDirectional.topCenter,
          ),
          Stack(
            children: [
              Container(
                color: Colors.grey,
                child:  _playViewWidget,
              ),
              playWidgetTopWidget()
            ], 
            alignment: AlignmentDirectional.topCenter,
          ),
           Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(child: Text('Publish StreamID:  ', style: TextStyle(fontSize: 11),), height: 32, alignment: Alignment.centerLeft,),
              SizedBox(
                width: MediaQuery.of(context).size.width *0.2,
                child:TextField(
                controller: _publishStreamIDController,
                style: TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                ),
              )),
            ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(child: Text('play StreamID:  ', style: TextStyle(fontSize: 11),), height: 32, alignment: Alignment.centerLeft,),
              SizedBox(
                width: MediaQuery.of(context).size.width *0.2,
                child:TextField(
                controller: _playStreamIDController,
                style: TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                ),
              )),
            ]),
        ],
        ));
  }
}



typedef RoomStateUpdateCallback = void Function(String, ZegoRoomState, int, Map<String, dynamic>);
typedef PublisherStateUpdateCallback = void Function(String, ZegoPublisherState, int, Map<String, dynamic>);
typedef PlayerStateUpdateCallback = void Function(String, ZegoPlayerState, int, Map<String, dynamic>);
typedef PublisherQualityUpdateCallback = void Function(String, ZegoPublishStreamQuality);
typedef PlayerQualityUpdateCallback = void Function(String streamID, ZegoPlayStreamQuality quality);

class ZegoDelegate {

  RoomStateUpdateCallback? _onRoomStateUpdate;
  PublisherStateUpdateCallback? _onPublisherStateUpdate;
  PlayerStateUpdateCallback? _onPlayerStateUpdate;
  PublisherQualityUpdateCallback? _onPublisherQualityUpdate;
  PlayerQualityUpdateCallback? _onPlayerQualityUpdate;

  late int _preViewID;
  late int _playViewID;
  Widget? preWidget;
  Widget? playWidget;
  ZegoDelegate() : _preViewID = -1 , _playViewID = -1;

  dispose() {
    _preViewID = -1;
    _playViewID = -1;
  }

  void _initCallback() {
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      print('🚩 🚪 Room state update, state: $state, errorCode: $errorCode, roomID: $roomID');
      _onRoomStateUpdate?.call(roomID, state, errorCode, extendedData);
    };  

    ZegoExpressEngine.onPublisherStateUpdate = (String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
      print('🚩 📤 Publisher state update, state: $state, errorCode: $errorCode, streamID: $streamID');
      if (state == ZegoPublisherState.Publishing && errorCode == 0)
      {
        print('🚩 📥 Publishing stream success');
      }
      if (errorCode != 0) {
        print('🚩 ❌ 📥 Publishing stream fail');
      }  
      _onPublisherStateUpdate?.call(streamID, state, errorCode, extendedData);
    };  

    ZegoExpressEngine.onPlayerStateUpdate = (String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData) {
      print('🚩 📥 Player state update, state: $state, errorCode: $errorCode, streamID: $streamID');
      if (state == ZegoPlayerState.Playing && errorCode == 0)
      {
        print('🚩 📥 Playing stream success');
      }
      if (errorCode != 0) {
        print('🚩 ❌ 📥 Playing stream fail');
      }    
      _onPlayerStateUpdate?.call(streamID, state, errorCode, extendedData);
    };  

    ZegoExpressEngine.onPublisherQualityUpdate = (String streamID, ZegoPublishStreamQuality quality) {
      print('🚩 📥 onPublisherQualityUpdate: streamID: $streamID');
      _onPublisherQualityUpdate?.call(streamID,quality);
    };  

    ZegoExpressEngine.onPlayerQualityUpdate = (String streamID, ZegoPlayStreamQuality quality) {
      print('🚩 📥 onPlayerQualityUpdate: streamID: $streamID');
      _onPlayerQualityUpdate?.call(streamID,quality);
    };  
  }

  void setZegoEventCallback(
    { RoomStateUpdateCallback? onRoomStateUpdate, 
      PublisherStateUpdateCallback? onPublisherStateUpdate,
      PlayerStateUpdateCallback? onPlayerStateUpdate,
      PublisherQualityUpdateCallback? onPublisherQualityUpdate,
      PlayerQualityUpdateCallback? onPlayerQualityUpdate,
    }) {
    if (onRoomStateUpdate != null)
    {
      _onRoomStateUpdate = onRoomStateUpdate;
    }
    if (onPublisherStateUpdate != null)
    {
      _onPublisherStateUpdate = onPublisherStateUpdate;
    }
    if (onPlayerStateUpdate != null)
    {
      _onPlayerStateUpdate = onPlayerStateUpdate;
    }
    if (onPublisherQualityUpdate != null)
    {
      _onPublisherQualityUpdate = onPublisherQualityUpdate;
    }
    if (onPlayerQualityUpdate != null)
    {
      _onPlayerQualityUpdate = onPlayerQualityUpdate;
    }
  }

  void clearZegoEventCallback() {
    _onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    
    _onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;

    _onPlayerStateUpdate = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;

    _onPublisherQualityUpdate = null;
    ZegoExpressEngine.onPublisherQualityUpdate = null;
  }

  Future<void> createEngine({bool? enablePlatformView}) async{
    _initCallback();

    await ZegoExpressEngine.destroyEngine();

    enablePlatformView = enablePlatformView?? ZegoConfig.instance.enablePlatformView;
    print("enablePlatformView :$enablePlatformView");
    ZegoEngineProfile profile = ZegoEngineProfile(
      ZegoConfig.instance.appID, 
      ZegoConfig.instance.scenario,
      enablePlatformView: enablePlatformView);
    await ZegoExpressEngine.createEngineWithProfile(profile);

    print('🚀 Create ZegoExpressEngine');
  }

  void destroyEngine() {
    ZegoExpressEngine.destroyEngine();
  }

  String roomStateDesc(ZegoRoomState roomState) {
    String result = 'Unknown';
    switch (roomState) {
      case ZegoRoomState.Disconnected:
        result = "Disconnected 🔴";
        break;
      case ZegoRoomState.Connecting:
        result = "Connecting 🟡";
        break;
      case ZegoRoomState.Connected:
        result = "Connected 🟢";
        break;
      default:
        result = "Unknown";
    }
    return result;
  }

  Future<void> loginRoom(String roomID) async {
    if (roomID.isNotEmpty )
    {
      // Instantiate a ZegoUser object
      ZegoUser user = ZegoUser(ZegoConfig.instance.userID, ZegoConfig.instance.userName.isEmpty? ZegoConfig.instance.userID: ZegoConfig.instance.userName);

      ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig();
      roomConfig.token = ZegoConfig.instance.token;
      // Login Room
      await ZegoExpressEngine.instance.loginRoom(roomID, user, config: roomConfig);

      print('🚪 Start login room, roomID: $roomID');
    }
  }

  Future<void> logoutRoom(String roomID) async {
    if (roomID.isNotEmpty)
    {
      await ZegoExpressEngine.instance.logoutRoom(roomID);

      print('🚪 Start logout room, roomID: $roomID');
    }
  }

  Future<Widget?> startPublishing(String streamID, {int width = 360, int height = 640, bool? enablePlatformView, String? roomID}) async {
    var publishFunc = (int viewID) {
      ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff));
      if (roomID != null) {
        ZegoExpressEngine.instance.startPublishingStream(streamID, config: ZegoPublisherConfig(roomID: roomID));
      } else {
        ZegoExpressEngine.instance.startPublishingStream(streamID);
      }
      print('📥 Start publish stream, streamID: $streamID');
    };

    if (streamID.isNotEmpty ) {
      if (_preViewID == -1)
      {
        if (enablePlatformView?? ZegoConfig.instance.enablePlatformView) {
          // Render with PlatformVie
            preWidget  = ZegoExpressEngine.instance.createPlatformView((viewID) {
              _preViewID = viewID;
              publishFunc(_preViewID);
            });
        } else {
          // Render with TextureRenderer
          var viewID = await ZegoExpressEngine.instance.createTextureRenderer(width, height);
          _preViewID = viewID;
          preWidget = Texture(textureId: _preViewID);
          publishFunc(_preViewID);
        }
      }
      else {
        publishFunc(_preViewID);
      }
    }
    return preWidget;
  }

  void stopPublishing() {
    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<Widget?> startPlaying(String streamID, {int width = 360, int height = 640, bool? enablePlatformView, String? cdnURL, bool needShow = true , String? roomID}) async {
    var playFunc = (int viewID) {
      ZegoCDNConfig? cdnConfig;
      if (cdnURL != null) {
        cdnConfig = ZegoCDNConfig(cdnURL, "");
      }

      if (needShow) {
        ZegoExpressEngine.instance.startPlayingStream(streamID, 
          canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff), 
          config: ZegoPlayerConfig(ZegoStreamResourceMode.Default, ZegoVideoCodecID.Default, cdnConfig: cdnConfig, roomID: roomID));
      }
      else{
        ZegoExpressEngine.instance.startPlayingStream(streamID,);
      }

            print('📥 Start publish stream, streamID: $streamID');
    };

    if (streamID.isNotEmpty) {
      if (_playViewID == -1 && needShow) {
        if (enablePlatformView?? ZegoConfig.instance.enablePlatformView) {
          // Render with PlatformView
          playWidget  = ZegoExpressEngine.instance.createPlatformView((viewID) {
              _playViewID = viewID;
              playFunc(_playViewID);
          });
        } else {
          // Render with TextureRenderer
          var viewID = await ZegoExpressEngine.instance.createTextureRenderer(width, height);
          playWidget = Texture(textureId: _playViewID);
          _playViewID = viewID;
          playFunc(_playViewID);
        }
      } else {
        playFunc(_playViewID);
      }
    }  
    return playWidget;
  }

  void stopPlaying(String streamID) {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }
}