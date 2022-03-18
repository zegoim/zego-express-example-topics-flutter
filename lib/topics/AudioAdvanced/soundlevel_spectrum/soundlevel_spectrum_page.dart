import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class SoundlevelSpectrumPage extends StatefulWidget {
  const SoundlevelSpectrumPage({ Key? key }) : super(key: key);

  @override
  _SoundlevelSpectrumPageState createState() => _SoundlevelSpectrumPageState();
}

class _SoundlevelSpectrumPageState extends State<SoundlevelSpectrumPage> {

  static const _roomID = 'soundlevel_spectrum';
  late String _streamID ;

  late ZegoRoomState _roomState;

  late double _soundlevel;
  late List<double> _spectrums;
  late List<Color> _spectrumColors;

  late bool _bSoundLevel;
  late bool _bSpectrum;

  late ZegoDelegate _zegoDelegate;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();

    _roomState = ZegoRoomState.Disconnected;
    _soundlevel = 0;
    _spectrums = [];
    _bSoundLevel = false;
    _bSpectrum = false;



    _spectrumColors = [];
    var random = Random();
    for (var i = 0; i < 64; i++) {
      _spectrumColors.add(Color.fromRGBO(random.nextInt(256), random.nextInt(256), random.nextInt(256), 1));
    }
      _streamID = 'soundlevel_spectrum_${random.nextInt(9999999).toString()}';

    _zegoDelegate.setZegoEventCallback(onRoomStateUpdate: onRoomStateUpdate, onCapturedAudioSpectrumUpdate: onCapturedAudioSpectrumUpdate, onCapturedSoundLevelUpdate: onCapturedSoundLevelUpdate);
    _zegoDelegate.createEngine().then((value) {
      _zegoDelegate.loginRoom(_roomID).then((value) {
        _zegoDelegate.startPublishing(_streamID);
      });
    });
  }

  @override
  void dispose() {
    _zegoDelegate.clearZegoEventCallback();
    _zegoDelegate.stopPublishing();
    _zegoDelegate.logoutRoom(_roomID);
    _zegoDelegate.destroyEngine();
    _zegoDelegate.dispose();
    super.dispose();
  }

  // zego express callback

  void onRoomStateUpdate(String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
    if (roomID == _roomID) {
      setState(() {
        _roomState = state;
      });
    }
  }

  void onCapturedSoundLevelUpdate(double soundLevel) {
    setState(() {
      _soundlevel = soundLevel;
    });
  }

  void onCapturedAudioSpectrumUpdate(List<double> audioSpectrum) {
    setState(() {
      _spectrums = audioSpectrum;
    });
  }

  // widget callback

  void onSoundlevelSwitchChanged(bool b) {
    setState(() {
      _bSoundLevel = b;
    });
    if (b) {
      _zegoDelegate.startSoundLevelMonitor();
    } else {
      _zegoDelegate.stopSoundLevelMonitor();
    }
  }

  void onSpectrumSwitchChanged(bool b) {
    setState(() {
      _bSpectrum = b;
    });
    if (b) {
      _zegoDelegate.startAudioSpectrumMonitor();
    } else {
      _zegoDelegate.stopAudioSpectrumMonitor();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音频频谱与音量变化'),),
      body: SafeArea(child: SingleChildScrollView(child: mainContent(context),)),
    );
  }

  Widget mainContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10,right: 10,top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roomInfoWidget(),
          spectrumAndSoundlevelWidget(context),
          setingWidget()
        ],
      ),
    );
  }

  Widget roomInfoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text("RoomID: $_roomID"),
      Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}'),
      Text('StreamID: $_streamID')
    ]);
  }

  Widget spectrumAndSoundlevelWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height*0.4,
          child: spectrumWidget(context),
        ),
        Row(
          children: [
            Text('Sound Wave '),
            Expanded(child:LinearProgressIndicator(value: _soundlevel/100.0,))
          ],
        )
      ],
    );
  }

  Widget setingWidget() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('开启声浪监听')),
            Switch(value: _bSoundLevel, onChanged: onSoundlevelSwitchChanged)
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('开启音频频谱监听')),
            Switch(value: _bSpectrum, onChanged: onSpectrumSwitchChanged)
          ],
        ),
      ],
    );
  }
  
  Widget spectrumWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _spectrums.asMap().map<int, Widget>((index, spectrum){
        print(log(spectrum));
        return MapEntry(index, RotatedBox(
          quarterTurns: -1,
          child: SizedBox(
            width: MediaQuery.of(context).size.height*0.4, 
            child: LinearProgressIndicator(
              backgroundColor: Colors.white, 
              color: _spectrumColors[index], 
              value: spectrum == 0? 0.25:(log(spectrum)+ 10)/30.0, 
              minHeight: MediaQuery.of(context).size.width/80,
            )
          )
        )) ;
      }).values.toList(),
    );
  }
}


typedef RoomStateUpdateCallback = void Function(String, ZegoRoomState, int, Map<String, dynamic>);
typedef CapturedSoundLevelUpdateCallback = void Function(double soundLevel);
typedef RemoteSoundLevelUpdateCallback = void Function(Map<String, double> soundLevels);
typedef CapturedAudioSpectrumUpdateCallback = void Function(List<double> audioSpectrum);
typedef RemoteAudioSpectrumUpdateCallback = void Function(Map<String, List<double>> audioSpectrums);

class ZegoDelegate {

  RoomStateUpdateCallback? _onRoomStateUpdate;
  CapturedSoundLevelUpdateCallback? _onCapturedSoundLevelUpdate;
  RemoteSoundLevelUpdateCallback? _onRemoteSoundLevelUpdate;
  CapturedAudioSpectrumUpdateCallback? _onCapturedAudioSpectrumUpdate;
  RemoteAudioSpectrumUpdateCallback? _onRemoteAudioSpectrumUpdate;

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

    ZegoExpressEngine.onCapturedSoundLevelUpdate = (double soundLevel) {
      _onCapturedSoundLevelUpdate?.call(soundLevel);
    };  

    ZegoExpressEngine.onRemoteSoundLevelUpdate = (Map<String, double> soundLevels) {
      _onRemoteSoundLevelUpdate?.call(soundLevels);
    };  

    ZegoExpressEngine.onCapturedAudioSpectrumUpdate = (List<double> audioSpectrum) {
      _onCapturedAudioSpectrumUpdate?.call(audioSpectrum);
    };  

    ZegoExpressEngine.onRemoteAudioSpectrumUpdate = (Map<String, List<double>> audioSpectrums) {
      _onRemoteAudioSpectrumUpdate?.call(audioSpectrums);
    };
  }

  void setZegoEventCallback(
    { RoomStateUpdateCallback? onRoomStateUpdate, 
      CapturedSoundLevelUpdateCallback? onCapturedSoundLevelUpdate,
      RemoteSoundLevelUpdateCallback? onRemoteSoundLevelUpdate,
      CapturedAudioSpectrumUpdateCallback? onCapturedAudioSpectrumUpdate,
      RemoteAudioSpectrumUpdateCallback? onRemoteAudioSpectrumUpdate,
    }) {
    if (onRoomStateUpdate != null)
    {
      _onRoomStateUpdate = onRoomStateUpdate;
    }
    if (onCapturedSoundLevelUpdate != null) {
      _onCapturedSoundLevelUpdate = onCapturedSoundLevelUpdate;
    }
    if (onRemoteSoundLevelUpdate != null) {
      _onRemoteSoundLevelUpdate = onRemoteSoundLevelUpdate;
    }
    if (onCapturedAudioSpectrumUpdate != null) {
      _onCapturedAudioSpectrumUpdate = onCapturedAudioSpectrumUpdate;
    }
    if (onRemoteAudioSpectrumUpdate != null) {
      _onRemoteAudioSpectrumUpdate = onRemoteAudioSpectrumUpdate;
    }
  }

  void clearZegoEventCallback() {
    _onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;

    _onCapturedSoundLevelUpdate = null;
    ZegoExpressEngine.onCapturedSoundLevelUpdate = null;

    _onRemoteSoundLevelUpdate = null;
    ZegoExpressEngine.onRemoteSoundLevelUpdate = null;

    _onCapturedAudioSpectrumUpdate = null;
    ZegoExpressEngine.onCapturedAudioSpectrumUpdate = null;

    _onRemoteAudioSpectrumUpdate = null;
    ZegoExpressEngine.onRemoteAudioSpectrumUpdate = null;
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
    if (roomID.isNotEmpty)
    {
         // Instantiate a ZegoUser object
      ZegoUser user = ZegoUser( ZegoConfig.instance.userID,  ZegoConfig.instance.userName.isEmpty? ZegoConfig.instance.userID: ZegoConfig.instance.userName);

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

  void startAudioSpectrumMonitor() {
    ZegoExpressEngine.instance.startAudioSpectrumMonitor();
  }

  void stopAudioSpectrumMonitor() {
    ZegoExpressEngine.instance.stopAudioSpectrumMonitor();
  }

  void startSoundLevelMonitor() {
    ZegoExpressEngine.instance.startSoundLevelMonitor();
  }

  void stopSoundLevelMonitor() {
    ZegoExpressEngine.instance.stopSoundLevelMonitor();
  }
}