import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class CommonVideoConfigPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CommonVideoConfigState();

}

class _CommonVideoConfigState extends State<CommonVideoConfigPage> with WidgetsBindingObserver{

  static const _roomID = 'video_config';

  late ZegoRoomState _roomState;

  late int _previewViewID;
  Widget? _previewViewWidget;
  late ZegoPublisherState _publisherState;
  late Key _previewViewContainerKey;
  late ZegoViewMode _preViewMode;
  late TextEditingController _publishingStreamIDController;


  late int _playviewViewID;
  Widget? _playViewWidget; 
  late ZegoPlayerState _playerState; 
  late Key _playViewContainerKey; 
  late ZegoViewMode _playViewMode;
  late TextEditingController _playingStreamIDController;

  late TextEditingController _encodingResolutionWController;
  late TextEditingController _encodingResolutionHController;

  late TextEditingController _frameRateController;
  late TextEditingController _bitRateController;
  static const double viewRatio = 3.0/6.0;
  late ZegoVideoMirrorMode _mirrorMode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addObserver(this);

    _roomState = ZegoRoomState.Disconnected;

    _previewViewID = -1;
    _publisherState = ZegoPublisherState.NoPublish;
    _previewViewContainerKey = GlobalKey();
    _preViewMode = ZegoViewMode.AspectFit;
    _publishingStreamIDController = new TextEditingController();
    _publishingStreamIDController.text = "video_config_room";

    _playviewViewID = -1;
    _playerState = ZegoPlayerState.NoPlay;
    _playViewContainerKey = GlobalKey();
    _playViewMode = ZegoViewMode.AspectFit;
    _playingStreamIDController = new TextEditingController();
    _playingStreamIDController.text = "video_config_room";

    _encodingResolutionWController = new TextEditingController();
    _encodingResolutionWController.text = "360";
    _encodingResolutionHController = new TextEditingController();
    _encodingResolutionHController.text = "720";

    _frameRateController = new TextEditingController();
    _frameRateController.text = "15";
    _bitRateController = new TextEditingController();
    _bitRateController.text = "600";
    _mirrorMode = ZegoVideoMirrorMode.NoMirror;

    getEngineConfig();
    setZegoEventCallback();
    createEngine();
    loginRoom();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // In iOS, there is no done key on the numeric keyboard, and the onEditingComplete of TextField cannot be triggered
      // Set video configuration parameters by listening for keyboard hiding
      if(MediaQuery.of(context).viewInsets.bottom==0){
          // close the keyboard
          setVideoConfig();
      }
    });
  }

  @override
  void dispose() {

    WidgetsBinding.instance?.removeObserver(this);
    // Can destroy the engine when you don't need audio and video calls
    //
    // Destroy engine will automatically logout room and stop publishing/playing stream.
    logoutRoom();
    clearZegoEventCallback();
    clearPreviewView();
    clearPlayView();
    ZegoExpressEngine.destroyEngine();

    print('🏳️ Destroy ZegoExpressEngine');

    super.dispose();
  }

  // widget callback
  
  void onStartPlayingStreamButtonPressed() {
    if (_playingStreamIDController.value.text.isEmpty)
    {
      return;
    }

    if (_playerState == ZegoPlayerState.Playing)
    {
      ZegoExpressEngine.instance.stopPlayingStream(_playingStreamIDController.value.text);
      print('Stop playing stream, streamID: ${_playingStreamIDController.value.text}');
    }
    else {

      if (ZegoConfig.instance.enablePlatformView) {
        // Render with PlatformView
        setState(() {
          _playViewWidget  = ZegoExpressEngine.instance.createPlatformView((viewID) {
            _playviewViewID = viewID;
            ZegoExpressEngine.instance.startPlayingStream(_playingStreamIDController.value.text, canvas: ZegoCanvas(_playviewViewID, viewMode: _playViewMode));
            print('📥 Start playing stream, streamID: ${_playingStreamIDController.value.text}');
          });
        });
      } else {
        // Render with TextureRenderer
        ZegoExpressEngine.instance.createTextureRenderer(360, 500).then((viewID) {
          _playviewViewID = viewID;
          setState(() => _playViewWidget  = Texture(textureId: viewID));
          ZegoExpressEngine.instance.startPlayingStream(_playingStreamIDController.value.text, canvas: ZegoCanvas(_playviewViewID, viewMode: _playViewMode));
          print('📥 Start playing stream, streamID: ${_playingStreamIDController.value.text}');
        });
      }
    }
  }

  void onPlayViewModeChanged(ZegoViewMode mode) {
    _playViewMode = mode;
    if (_playerState == ZegoPlayerState.Playing) {
      ZegoExpressEngine.instance.stopPlayingStream(_playingStreamIDController.value.text).then((value) {
        Timer(Duration(milliseconds: 50), (){
          onStartPlayingStreamButtonPressed();       
        }) ;
      } );
    } 
    print('🚀 set PlayView Mode : $mode');
  }

  void onPreViewModeChanged(ZegoViewMode mode) {
    _preViewMode = mode;
    ZegoExpressEngine.instance.stopPreview().then((value) => startPreview());
    print('🚀 set PreView Mode : $mode');
  }

  void onMirrorModeChanged(ZegoVideoMirrorMode mode)
  {
    ZegoExpressEngine.instance.setVideoMirrorMode(mode);
    setState(() {
      _mirrorMode = mode;
    });
  }

  void onEncodeResolutionWidthChanged(int encodeWidth)
  {
    setVideoConfig(encodeWidth: encodeWidth);
  }

  void onEncodeResolutionHeightChanged(int encodeHeight)
  {
    setVideoConfig(encodeHeight: encodeHeight);
  }

  void onVideoFpsChanged(int fps)
  {
    setVideoConfig(fps: fps);
  }

  void onVideoBitrateChanged(int bitrate)
  {
    setVideoConfig(bitrate: bitrate);
  }

  // widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Common Video Config')),
      body: SafeArea(child: GestureDetector(
        child: mainContent(context),
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      )),
    );
  }
  
  Widget mainContent(BuildContext context) {
    return SingleChildScrollView(child: Column(
      children: [
        roomInfoWidget(),
        streamViewWidget(),
        videoSettingWidget(),
      ],
    ),);
  }

  Widget roomInfoWidget() {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10), child:Row(children: [
      Text("RoomID: $_roomID"),
      Spacer(),
      Text(roomStateDesc()),
    ]));
  }

  Widget streamViewWidget() {
    return Container(
      height: MediaQuery.of(context).size.width,
      child: GridView(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: viewRatio,
        ),
        children: [
          viewsWidget(true),
          viewsWidget(false)
        ],)
    );
  }

  Widget videoSettingWidget() {
    return Column(
      children: [
        encodingResolutionWidget(),
        Padding(padding: EdgeInsets.only(top: 10)),
        frameRateAndBitRateWidget(),
        Padding(padding: EdgeInsets.only(top: 10)),
        mirrorModeWidget()
    ],);
  }

  Widget viewsWidget(bool isPreView) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [ 
        Expanded(
          child:
          Stack(children: [
          Container(
            color: Colors.grey,
            child: isPreView? _previewViewWidget : _playViewWidget,
            key: isPreView? _previewViewContainerKey : _playViewContainerKey,
          ),
          Text(isPreView? 'Local Preview View' :'Remote Play View', 
            style: TextStyle(color: Colors.white))
        ], alignment: AlignmentDirectional.topCenter,)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('View Mode',style: TextStyle(fontSize: 12.0)),
            DropdownButton(
            value: isPreView? _preViewMode :_playViewMode,
            items: [
              DropdownMenuItem(child: Text("AspectFit",style: TextStyle(fontSize: 12.0)), value: ZegoViewMode.AspectFit,),
              DropdownMenuItem(child: Text("AspectFill",style: TextStyle(fontSize: 12.0)), value: ZegoViewMode.AspectFill,),
              DropdownMenuItem(child: Text("ScaleToFill",style: TextStyle(fontSize: 12.0)), value: ZegoViewMode.ScaleToFill,)
            ],onChanged: (ZegoViewMode? mode) {
              if (mode == null)
              {
                return;
              }
              if (isPreView) {
                _preViewMode = mode;
                onPreViewModeChanged(mode);
                setState(() {});        
              }
              else{
                _playViewMode = mode;
                onPlayViewModeChanged(mode);
                setState(() {}); 
              }     
            },)
          ]),
        TextField(
              controller: isPreView? _publishingStreamIDController : _playingStreamIDController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                labelText: isPreView? 'Play StreamID:' : 'Publish StreamID:',
                labelStyle: TextStyle(color: Colors.black54, fontSize: 14.0),
                hintText: 'Please enter streamID',
                hintStyle: TextStyle(color: Colors.black26, fontSize: 10.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            ),
        Padding(padding: EdgeInsets.only(top: 10)),
        CupertinoButton.filled(
          child: Text(
            isPreView? (_publisherState == ZegoPublisherState.Publishing ? '✅ StopPublishing' : 'StartPublishing'):
              (_playerState == ZegoPlayerState.Playing ? '✅ StopPlaying' : 'StartPlaying'), 
            style: TextStyle(fontSize: 14.0),),
          onPressed: isPreView? startPublishingStream: onStartPlayingStreamButtonPressed,
          padding: EdgeInsets.all(10.0),
        )
      ]);
  }

  Widget encodingResolutionWidget() {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Text('编码分辨率')),
            SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child: TextField(
              controller: _encodingResolutionWController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                if (_encodingResolutionWController.text.isNotEmpty)
                {
                  onEncodeResolutionWidthChanged(int.parse(_encodingResolutionWController.text));
                }
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[0-9]")),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            )),
            Padding(padding: EdgeInsets.only(right: 5, left: 5), child:Text('x')),
            SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child:TextField(
              controller: _encodingResolutionHController,
              keyboardType: TextInputType.number,
              onEditingComplete: () {
                if (_encodingResolutionHController.text.isNotEmpty) {
                  onEncodeResolutionHeightChanged(int.parse(_encodingResolutionHController.text));
                }              
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[0-9]")),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            )),
          ]
        ));
  }

  Widget frameRateAndBitRateWidget() {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Row(
      children: [
        Padding(padding: EdgeInsets.only(right: 5), child:Text('视频帧率')),
        SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child:TextField(
              controller: _frameRateController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[0-9]")),
              ],
              onEditingComplete: () {
                if (_frameRateController.text.isNotEmpty)
                {
                  onVideoFpsChanged(int.parse(_frameRateController.text));
                }           
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),)),
        Expanded(child: Container()),
        Padding(padding: EdgeInsets.only(right: 5), child:Text('视频码率')),
        SizedBox(
              width: MediaQuery.of(context).size.width *0.2,
              child:TextField(
              controller: _bitRateController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[0-9]")),
              ],
              onEditingComplete: () {
                if (_bitRateController.text.isNotEmpty)
                {
                  onVideoBitrateChanged(int.parse(_bitRateController.text));
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),)),
      ],
    ));
  }

  Widget mirrorModeWidget() {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Row(
      children: [
        Expanded(child: Text('镜像模式')),
        DropdownButton(
            value: _mirrorMode,
            items: [
              DropdownMenuItem(child: Text("OnlyPreview",style: TextStyle(fontSize: 12.0)), value: ZegoVideoMirrorMode.OnlyPreviewMirror,),
              DropdownMenuItem(child: Text("OnlyPublish",style: TextStyle(fontSize: 12.0)), value: ZegoVideoMirrorMode.OnlyPublishMirror,),
              DropdownMenuItem(child: Text("Both",style: TextStyle(fontSize: 12.0)), value: ZegoVideoMirrorMode.BothMirror,),
              DropdownMenuItem(child: Text("None",style: TextStyle(fontSize: 12.0)), value: ZegoVideoMirrorMode.NoMirror,)
            ],onChanged: (ZegoVideoMirrorMode?mode) {
              if (mode == null)
              {
                return;
              }
              onMirrorModeChanged(mode);
            })
      ])
    );
  }

  // zego 

  void clearPreviewView() {
    if (_previewViewWidget == null) {
      return;
    }

    // Developers should destroy the [PlatformView] or [TextureRenderer] after
    // [stopPublishingStream] or [stopPreview] to release resource and avoid memory leaks
    if (ZegoConfig.instance.enablePlatformView) {
      ZegoExpressEngine.instance.destroyPlatformView(_previewViewID);
    } else {
      ZegoExpressEngine.instance.destroyTextureRenderer(_previewViewID);
    }
  }

  void clearPlayView() {
    if (_playViewWidget == null) {
      return;
    }

    // Developers should destroy the [PlatformView] or [TextureRenderer]
    // after [stopPlayingStream] to release resource and avoid memory leaks
    if (ZegoConfig.instance.enablePlatformView) {
      ZegoExpressEngine.instance.destroyPlatformView(_playviewViewID);
    } else {
      ZegoExpressEngine.instance.destroyTextureRenderer(_playviewViewID);
    }
  }

  void getEngineConfig() {
    ZegoExpressEngine.getVersion().then((value) => print('🌞 SDK Version: $value'));
  }

  void setZegoEventCallback() {
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      print('🚩 🚪 Room state update, state: $state, errorCode: $errorCode, roomID: $roomID');
      setState(() => _roomState = state);
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
      setState(() => _publisherState = state);
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
      setState(() => _playerState = state);
    };
  }

  void clearZegoEventCallback() {
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;
  }

  void createEngine() {
    ZegoEngineProfile profile = ZegoEngineProfile(
      ZegoConfig.instance.appID, 
      ZegoConfig.instance.scenario,
      enablePlatformView: ZegoConfig.instance.enablePlatformView);
    ZegoExpressEngine.createEngineWithProfile(profile).then((value) => startPreview());

    print('🚀 Create ZegoExpressEngine');
  }

  void startPreview() {
    if (ZegoConfig.instance.enablePlatformView) {
      // Render with PlatformView
      setState(() {
        _previewViewWidget  = ZegoExpressEngine.instance.createPlatformView((viewID) {
          _previewViewID = viewID;
          ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(_previewViewID, viewMode: _preViewMode));
          print('🔌 Start preview');
        });
      });
    } else {
      // Render with TextureRenderer
      ZegoExpressEngine.instance.createTextureRenderer(360, 500).then((viewID) {
        _previewViewID = viewID;
        setState(() => _previewViewWidget  = Texture(textureId: viewID));
        ZegoExpressEngine.instance.startPreview(canvas: ZegoCanvas(_previewViewID, viewMode: _preViewMode));
        print('🔌 Start preview');
      });
    }
  }

  void loginRoom() {
    // Instantiate a ZegoUser object
    ZegoUser user = ZegoUser(ZegoConfig.instance.userID, ZegoConfig.instance.userName);

    // Login Room
    ZegoExpressEngine.instance.loginRoom(_roomID, user, config: ZegoRoomConfig(0, true, ZegoConfig.instance.token));

    print('🚪 Start login room, roomID: $_roomID');
  }

  void logoutRoom() {
    print('🚪 Start logout room, roomID: $_roomID');
    if (_roomState == ZegoRoomState.Connected) {
      ZegoExpressEngine.instance.logoutRoom(_roomID);
    }
  }

  void startPublishingStream() {
    if (_publishingStreamIDController.value.text.isEmpty)
    { 
      return;
    }
    if (_publisherState ==  ZegoPublisherState.Publishing)
    {
      ZegoExpressEngine.instance.stopPublishingStream();
      print('📤 Stop publishing stream.');
    }
    else
    {
      ZegoExpressEngine.instance.startPublishingStream(_publishingStreamIDController.value.text);
      print('📤 Start publishing stream. streamID: ${_publishingStreamIDController.value.text}');
    }
  }

  void setVideoConfig({int? encodeWidth, int? encodeHeight, int? fps, int? bitrate}) {
    if (encodeWidth == null && _encodingResolutionWController.text.isNotEmpty)
    {
      encodeWidth = int.parse(_encodingResolutionWController.text);
    }
    if (encodeHeight == null && _encodingResolutionHController.text.isNotEmpty)
    {
      encodeHeight = int.parse(_encodingResolutionHController.text);
    }
    if (fps == null && _frameRateController.text.isNotEmpty)
    {
      fps = int.parse(_frameRateController.text);
    }
    if (bitrate == null && _bitRateController.text.isNotEmpty)
    {
      bitrate = int.parse(_bitRateController.text);
    }
    print("encodeWidth: $encodeWidth, encodeHeight: $encodeHeight, fps: $fps, bitrate: $bitrate");
    var config = ZegoVideoConfig.preset(ZegoVideoConfigPreset.Preset360P);
    config.encodeWidth = encodeWidth?? 360;
    config.encodeHeight = encodeHeight?? 640;
    config.fps = fps?? 15;
    config.bitrate = bitrate?? 300;
    ZegoExpressEngine.instance.setVideoConfig(config);
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