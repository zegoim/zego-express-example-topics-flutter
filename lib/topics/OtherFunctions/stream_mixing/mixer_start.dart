import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class MixerStartPage extends StatefulWidget {
  const MixerStartPage({ Key? key }) : super(key: key);

  @override
  _MixerStartPageState createState() => _MixerStartPageState();
}

class _MixerStartPageState extends State<MixerStartPage> {

  Widget? _view;
  late bool _useCamera;
  late bool _useMic;
  late Map<String ,bool> _streamMap;
  final mixStreamID = 'mixer_start';

  final _roomID = 'mixer';

  late ZegoDelegate _zegoDelegate;
  
  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();

    _useCamera = true;
    _useMic = true;

    _streamMap = {};

    _zegoDelegate.setZegoEventCallback(onRoomStreamUpdate: onRoomStreamUpdate);
    _zegoDelegate.createEngine(enablePlatformView: true).then((value) {
      _zegoDelegate.loginRoom(_roomID, ZegoConfig.instance.userID);
    });
  }

  @override
  void dispose() {
    _zegoDelegate.clearZegoEventCallback();
    _zegoDelegate.logoutRoom(_roomID);
    _zegoDelegate.destroyEngine();
    _zegoDelegate..dispose();
    super.dispose();
  }

  void onStartBtnPress() async{
    var streamIDList = <String>[];
    for (var stream in _streamMap.keys) {
      if (_streamMap[stream]!) {
        streamIDList.add(stream);
      }
    }
    if (streamIDList.length < 2) {
        return;
    }

    ZegoMixerStartResult result = await _zegoDelegate.startMixerTask(streamIDList, mixStreamID);
    print('startMixerTask: errorCode: ${result.errorCode}  extendedData:${result.extendedData}');

    _view = await _zegoDelegate.startPlaying(mixStreamID, enablePlatformView: true);
    setState(() {
      
    });
  }

  void onStopBtnPress() {
    _zegoDelegate.stopPlaying(mixStreamID);
  }

  void onStopMixingBtnPress() {
    var streamIDList = <String>[];
    for (var stream in _streamMap.keys) {
      if (_streamMap[stream]!) {
        streamIDList.add(stream);
      }
    }
    if (streamIDList.length < 2) {
        return;
    }
    _zegoDelegate.stopMixerTask(streamIDList, mixStreamID).then((value) {
      print('stopMixerTask: errorCode: ${value.errorCode}');
    });
  }

  void onCamareBtnPress() {
    setState(() {
      _useCamera = !_useCamera;
    });
    _zegoDelegate.enableCamare(_useCamera);
  }

  void onMicBtnPress() {
    setState(() {
      _useMic = !_useMic;
    });
    _zegoDelegate.enableAudioCaptureDevice(_useMic);
  }

  void onRoomStreamUpdate(String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
    if (updateType == ZegoUpdateType.Add) {
      for (var stream in streamList) {
         _streamMap[stream.streamID] = false;
      }
    }
    else {
      for (var stream in streamList) {
         _streamMap.remove(stream.streamID);
      }
    }
    setState(() {
      
    });
  }

  Widget view() {
    return Stack(
      children: [
        Container(
          color: Colors.grey,
          width: MediaQuery.of(context).size.width*0.6,
          height: MediaQuery.of(context).size.width*0.8,
          child: _view,),
        Positioned(right: 55, bottom: 5, width: 40, height: 40,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle , color: _useCamera? Colors.white:Colors.black38), 
            child: IconButton(color: _useCamera? Colors.black:Colors.white, onPressed: onCamareBtnPress, icon: Icon(Icons.camera_alt)))),
        Positioned(right: 5, bottom: 5, width: 40, height: 40,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle , color: _useMic? Colors.white: Colors.black38), 
            child: IconButton(color: _useMic? Colors.black:Colors.white, onPressed: onMicBtnPress, icon: Icon(Icons.mic))))
      ],
    );
  }

  Widget streamWidget(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height*0.2,
      child: ListView.builder(itemBuilder: (context, index) {
        return Row(
          children: [
            Checkbox(value: _streamMap.values.toList()[index], onChanged: (bool? b) {
              if (b != null) {
                setState(() {
                  _streamMap[_streamMap.keys.toList()[index]] = b;
                });
              }
            }),
            Text('${_streamMap.keys.toList()[index]}')
          ],
        );
      }, itemCount: _streamMap.length,)
    );
  }

  Widget mainWidget() {
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Text('RoomID:    mixer'),
          Padding(padding: EdgeInsets.only(top: 10)),
          Center( child: view(),),
          Padding(padding: EdgeInsets.only(top: 10)),
          Text('请选择2条远端的流参与混流'),
          Padding(padding: EdgeInsets.only(top: 10)),
          streamWidget(context),
          Padding(padding: EdgeInsets.only(top: 10)),
          SizedBox( width: MediaQuery.of(context).size.width*0.7, 
            child: CupertinoButton.filled(
              child: Text('1.发起并观看混流',),
              onPressed: onStartBtnPress,
              padding: EdgeInsets.only(top:10, bottom: 10)
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          SizedBox( width: MediaQuery.of(context).size.width*0.7, 
            child: CupertinoButton.filled(
              child: Text('2.停止观看混流',),
              onPressed: onStopBtnPress,
              padding: EdgeInsets.only(top:10, bottom: 10)
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          SizedBox( width: MediaQuery.of(context).size.width*0.7, 
            child: CupertinoButton.filled(
              child: Text('3.停止混流',),
              onPressed: onStopMixingBtnPress,
              padding: EdgeInsets.only(top:10, bottom: 10)
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("混流"),),
      body: SafeArea(child: SingleChildScrollView(child: mainWidget())),
    );
  }
}

typedef RoomStreamUpdateCallback = void Function(String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData);

class ZegoDelegate {
  RoomStreamUpdateCallback? _onRoomStreamUpdate;

  late int _playViewID;
  Widget? playWidget;

  ZegoDelegate() : _playViewID = -1;

  dispose() {
    _playViewID = -1;
  }

  void _initCallback() {
    
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      print('🚩 📥 onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList:${streamList.length}, streamList: [');
      for (var stream in streamList) {  
        print('streamID: ${stream.streamID}');
      }
      print(']');
      _onRoomStreamUpdate?.call(roomID,updateType, streamList, extendedData);
    };  
  }

  void setZegoEventCallback(
    { 
      RoomStreamUpdateCallback? onRoomStreamUpdate,
    }) {
    
    if (onRoomStreamUpdate != null) {
      _onRoomStreamUpdate = onRoomStreamUpdate;
    }
  }

  void clearZegoEventCallback() {

    _onRoomStreamUpdate = null;
    ZegoExpressEngine.onPublisherQualityUpdate = null;
  }

  void enableCamare(bool enable) {
    ZegoExpressEngine.instance.enableCamera(enable);
  }

  void enableAudioCaptureDevice(bool enable) {
    ZegoExpressEngine.instance.enableAudioCaptureDevice(enable);
  }

  Future<void> createEngine({bool? enablePlatformView}) async{
    _initCallback();

    await ZegoExpressEngine.destroyEngine();

    enablePlatformView = enablePlatformView?? ZegoConfig.instance.enablePlatformView;
    print("enablePlatformView :$enablePlatformView");
    ZegoEngineProfile profile = ZegoEngineProfile(
      ZegoConfig.instance.appID, 
      ZegoConfig.instance.appSign, 
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

  Future<void> loginRoom(String roomID, String userID, {String? userName}) async {
    if (roomID.isNotEmpty && userID.isNotEmpty)
    {
         // Instantiate a ZegoUser object
      ZegoUser user = ZegoUser(userID, userName?? userID);

      // Login Room
      await ZegoExpressEngine.instance.loginRoom(roomID, user);

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

  Future<Widget?> startPlaying(String streamID, {int width = 360, int height = 640, bool? enablePlatformView, String? cdnURL, bool needShow = true , String? roomID}) async {
    var playFunc = (int viewID) {
      ZegoCDNConfig? cdnConfig;
      if (cdnURL != null) {
        cdnConfig = ZegoCDNConfig(cdnURL, "");
      }

      if (needShow) {
        ZegoExpressEngine.instance.startPlayingStream(streamID, 
          canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff), 
          config: ZegoPlayerConfig(ZegoStreamResourceMode.Default, cdnConfig: cdnConfig, roomID: roomID));
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
  
  Future<ZegoMixerStartResult> startMixerTask(List<String> streamIDList, String mixStreamID) {
    var task = ZegoMixerTask("task1");
    List<ZegoMixerInput> inputList = [];
    var random = Random();
    int index = 0;
    for (var streamID in streamIDList) {
      ZegoMixerInput input = ZegoMixerInput(streamID, ZegoMixerInputContentType.Video, Rect.fromLTWH(0, index*320, 360, 320), random.nextInt(100000), true, 0,);
      inputList.add(input);
      index ++;
    }

    List<ZegoMixerOutput> outputList = [];
    ZegoMixerOutput output = ZegoMixerOutput(mixStreamID);
    ZegoMixerAudioConfig audioConfig = ZegoMixerAudioConfig.defaultConfig();
    ZegoMixerVideoConfig videoConfig = ZegoMixerVideoConfig.defaultConfig();
    task.videoConfig = videoConfig;
    task.audioConfig = audioConfig;
    outputList.add(output);
    task.enableSoundLevel = true;
    task.inputList = inputList;
    task.outputList = outputList;

    ZegoWatermark watermark = new ZegoWatermark("preset-id://zegowp.png", Rect.fromLTRB(0,0,180,120));
    task.watermark = watermark;

    task.backgroundImageURL = "preset-id://zegobg.png";

    return ZegoExpressEngine.instance.startMixerTask(task);
  }


  Future<ZegoMixerStopResult> stopMixerTask(List<String> streamIDList, String mixStreamID) {
    var task = ZegoMixerTask("task1");
    List<ZegoMixerInput> inputList = [];
    int index = 0;
    for (var streamID in streamIDList) {
      ZegoMixerInput input = ZegoMixerInput(streamID, ZegoMixerInputContentType.Video, Rect.fromLTRB(0, 0, 360, 320), index, true, 0,);
      inputList.add(input);
      index ++;
    }

    List<ZegoMixerOutput> outputList = [];
    ZegoMixerOutput output = ZegoMixerOutput(mixStreamID);
    ZegoMixerAudioConfig audioConfig = ZegoMixerAudioConfig.defaultConfig();
    ZegoMixerVideoConfig videoConfig = ZegoMixerVideoConfig.defaultConfig();
    task.videoConfig = videoConfig;
    task.audioConfig = audioConfig;
    outputList.add(output);
    task.enableSoundLevel = true;
    task.inputList = inputList;
    task.outputList = outputList;

    ZegoWatermark watermark = new ZegoWatermark("preset-id://zegowp.png", Rect.fromLTRB(0,0,300,200));
    task.watermark = watermark;

    task.backgroundImageURL = "preset-id://zegobg.png";

    return ZegoExpressEngine.instance.stopMixerTask(task);
  }
}