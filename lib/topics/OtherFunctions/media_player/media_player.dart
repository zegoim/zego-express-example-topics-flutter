import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_slider_bar.dart';

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({required this.url, this.isVideo = false,Key? key }) : super(key: key);

  final String url;
  final bool isVideo;

  @override
  _MediaPlayerPageState createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {

  late ZegoRoomState _roomState;
  final String _roomID = "mediaplayer";
  final String _streamID = "mediaplayer";
  static const double viewRatio = 3.0/4.0;

  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;
  Widget? _mediaplayerWidget;

  late StreamController<double> _playProgressStreamController;
  late StreamController<double> _volumeProgressStreamController;
  late StreamController<double> _volumeHighProgressStreamController;
  late StreamController<double> _speedProgressStreamController;

  static const double _initVolume = 0.30;
  static const double _initVolumeHigh = 0.0;
  static const double _volumeHighMin = -8.0;
  static const double _volumeHighMax = 8.0;
  static const double _initSpeed = 1.0;
  static const double _speedMin = 0.5;
  static const double _speedMax = 2.0;

  late bool _repeat;
  late bool _enableAux;
  late bool _muteLocal;

  late int _audioTrackIndex;
  
  late double _volumeHigh;
  late double _speed;

  late ZegoDelegate _zegoDelegate;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();
    
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;
    _roomState = ZegoRoomState.Disconnected;

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate:onRoomStateUpdate, 
        onPublisherStateUpdate:onPublisherStateUpdate, 
        onPlayerStateUpdate:onPlayerStateUpdate,
        onMediaPlayerPlayingProgress:onMediaPlayerPlayingProgress);
    _zegoDelegate.createEngine(enablePlatformView: true).then((value) {
      _zegoDelegate.loginRoom(_roomID, ZegoConfig.instance.userID).then((value) {
        _zegoDelegate.createMediaPlayer().then((view) {
          setState(() {
            _mediaplayerWidget = view;
          });
          _zegoDelegate.setVolumeMediaPlayer(_initVolume);
          _zegoDelegate.loadResourceMediaPlayer(widget.url).then((value) => print("loadresource errorcode: $value"));
        });
      });
    });

    _playProgressStreamController = StreamController();
    _volumeProgressStreamController = StreamController();
    _volumeHighProgressStreamController = StreamController();
    _speedProgressStreamController = StreamController();

    _repeat = false;
    _enableAux = false;
    _muteLocal = false;

    _audioTrackIndex = 0;

    _volumeHigh = 0;
    _speed = 1;
  }

  @override
  void dispose() {
    _zegoDelegate.destroyMediaPlayer();

    _zegoDelegate.logoutRoom(_roomID);

    _zegoDelegate.clearZegoEventCallback();

    ZegoExpressEngine.destroyEngine();

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

  void onMediaPlayerPlayingProgress(double pregress) {
    print("pregress: $pregress");
    _playProgressStreamController.sink.add(pregress);
  }

  void onPublishStreamBtnPress() {
    if (_publisherState != ZegoPublisherState.Publishing)
    {
      _zegoDelegate.startPublishing(_streamID, enablePlatformView: true).then((widget){
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
    if (_playerState != ZegoPlayerState.Playing)
    {
      _zegoDelegate.startPlaying(_streamID, enablePlatformView: true).then((widget) {
        setState(() {
          _playViewWidget = widget;
        });
      });
    }
    else{
      _zegoDelegate.stopPlaying(_streamID);
    }
  }

  void onPlayerProgressChanged(double progress) {
    _zegoDelegate.seekToMediaPlayer(progress);
  }

  void onVolumeChanged(double volume) {
    _zegoDelegate.setVolumeMediaPlayer(volume);
  }

  void onVolumeHighChanged(double volume) {
    setState(() {
      _volumeHigh = volume;
    });
    _zegoDelegate.setVoiceChangerParamMediaPlayer(volume);
  }

  void onSpeedChanged(double speed) {
    setState(() {
      _speed = speed;
    });
    _zegoDelegate.setPlaySpeedMediaPlayer(speed);
  } 

  void onStartBtnPress() {
    _zegoDelegate.startMediaPlayer();
  }

  void onPauseBtnPress() {
    _zegoDelegate.pauseMediaPlayer();
  }

  void onResumeBtnPress() {
    _zegoDelegate.resumeMediaPlayer();
  }

  void onStopBtnPress() async{
    _playProgressStreamController.sink.add(0);
    await _zegoDelegate.seekToMediaPlayer(0);
    _zegoDelegate.stopMediaPlayer();
  }

  void onRepeatSwitch(bool enable) {
    setState(() {
      _repeat = enable;
    });
    _zegoDelegate.repeatMediaPlayer(enable);
  }

  void onEnablAuxSwitch(bool enable) {
    setState(() {
      _enableAux = enable;
    });
    _zegoDelegate.enableAuxMediaPlayer(enable);
  }

  void onMuteLocalSwitch(bool mute) {
    setState(() {
      _muteLocal = mute;
    });
    _zegoDelegate.muteLocalMediaPlayer(mute);
  }

  void onAudioTrackIndexRadio(int? index) {
    if (index == null)
    {
      return;
    }
    setState(() {
      _audioTrackIndex = index;
    });
    _zegoDelegate.setAudioTrackIndexMediaPlayer(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Media Player"),),
      body: SafeArea(child: 
        SingleChildScrollView(
          child: Column(
            children: [
              roomInfoWidget(context),
              ListTile(tileColor: Colors.grey, title: Text("Publish")),
              streamViewsWidget(),
              ListTile(tileColor: Colors.grey, title: Text("Media Player")),
              mediaPlayerWidget(context),
              ListTile(tileColor: Colors.grey, title: Text("Media Player Setting")),
              mediaPlayerSettingWidget(context)
            ],
          ),
        )
      ),
    );
  }

  Widget roomInfoWidget(context) {
    return Padding(padding: EdgeInsets.only(left: 10,right: 10, bottom: 5), 
    child:  Wrap(
      spacing: MediaQuery.of(context).size.width* 0.1,
      runSpacing: 10,
      children: [
      Text('RoomID: $_roomID'),
      Text('StreamID: $_streamID'),
      Text('UserID: ${ZegoConfig.instance.userID}'),
      Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}')
    ],));
  }

  Widget mediaPlayerWidget(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10), 
          child: Text('Media Type ${widget.isVideo? "Video": "Audio" }',), 
          alignment: Alignment.centerLeft,
        ),
        Container(
          color: Colors.amberAccent,
          width: MediaQuery.of(context).size.width, 
          height: MediaQuery.of(context).size.height*0.2,
          child: _mediaplayerWidget,
        ),
        ZegoSliderBar(progressStream: _playProgressStreamController.stream, onProgressChanged: onPlayerProgressChanged),
        // Slider(value: _playProgress, onChanged: (double value) {}, onChangeEnd: onPlayerProgressChanged, onChangeStart: (value) => isSlider = true,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(onPressed: onStartBtnPress, child: Text("START")),
            TextButton(onPressed: onPauseBtnPress, child: Text("PAUSE")),
            TextButton(onPressed: onResumeBtnPress, child: Text("RESUME")),
            TextButton(onPressed: onStopBtnPress, child: Text("STOP")),
          ],
        )
      ],
    );
  }

  Widget mediaPlayerSettingWidget(context) {
    return Padding(padding: EdgeInsets.only(left: 15, right: 15), 
    child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Volume'),
              SizedBox(width: MediaQuery.of(context).size.width*0.6, 
                child: ZegoSliderBar(onProgressChanged: onVolumeChanged, value: _initVolume,),
              )
          ],),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              Row(children: [
                Text('Repeat'),
                Switch(value: _repeat, onChanged: onRepeatSwitch)
              ],) ,
              Row(children: [
                Text('Enable Aux'),
                Switch(value: _enableAux, onChanged: onEnablAuxSwitch),
              ],),
              Row(children: [
                Text('Mute Local'),
                Switch(value: _muteLocal, onChanged: onMuteLocalSwitch)
              ],),
            ],
          ),
          Row(
            children: [
              Text('Audio Track Index'),
              Expanded(child: Container()),
              Radio<int>(value: 0, groupValue: _audioTrackIndex, onChanged: onAudioTrackIndexRadio),
              Radio<int>(value: 1, groupValue: _audioTrackIndex, onChanged: onAudioTrackIndexRadio),
            ],
          ),
          Row(
            children: [
              Text('音高 '),
              Text('${_volumeHigh.toStringAsFixed(2)}'),
              Expanded(child: Container()),
              SizedBox(width: MediaQuery.of(context).size.width*0.6, child:
                ZegoSliderBar(onProgressChanged: onVolumeHighChanged, value: _initVolumeHigh, min: _volumeHighMin, max: _volumeHighMax,realTimeRefresh: true))
            ],
          ),
          Row(
            children: [
              Text('倍速 '),
              Text('${_speed.toStringAsFixed(2)}'),
              Expanded(child: Container()),
              SizedBox(width: MediaQuery.of(context).size.width*0.6, child:
                ZegoSliderBar(onProgressChanged: onSpeedChanged, value: _initSpeed, min: _speedMin, max: _speedMax, realTimeRefresh: true,))
            ],
          )
        ]
      )
    );
  }

  Widget streamViewsWidget() {
    // 预览界面上面的按钮和标题
    Widget topPreViewWidet = Padding(padding: EdgeInsets.only(bottom: 10),child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Local Preview View', 
            style: TextStyle(color: Colors.white)),
          // Expanded(child: Container()),
        CupertinoButton.filled(
          child: Text(
            _publisherState == ZegoPublisherState.Publishing ? '✅ StopPublishing' : 'StartPublishing', 
            style: TextStyle(fontSize: 14.0),),
          onPressed: onPublishStreamBtnPress,
          padding: EdgeInsets.all(10.0),
        )
      ]
    ));
    // 拉流界面上面的按钮和标题
    Widget topPlayViewWidet = Padding(padding: EdgeInsets.only(bottom: 10),child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Remote Play View', 
            style: TextStyle(color: Colors.white)),
        CupertinoButton.filled(
          child: Text(_playerState == ZegoPlayerState.Playing ? '✅ StopPlaying' : 'StartPlaying', 
            style: TextStyle(fontSize: 14.0),),
          onPressed: onPlayStreamBtnPress,
          padding: EdgeInsets.all(10.0),
        )
      ]
    ));
    return Container(
      height: MediaQuery.of(context).size.height *0.3,
      child:GridView(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: viewRatio,
        ),
        children: [
          Stack(children: [
          Container(
            color: Colors.grey,
            child: _previewViewWidget,
          ),
          topPreViewWidet
        ], alignment: AlignmentDirectional.topCenter,),
          Stack(children: [
          Container(
            color: Colors.grey,
            child:  _playViewWidget,
          ),
          topPlayViewWidet
        ], alignment: AlignmentDirectional.topCenter,)
        ],
        ));
  }
}



typedef RoomStateUpdateCallback = void Function(String, ZegoRoomState, int, Map<String, dynamic>);
typedef PublisherStateUpdateCallback = void Function(String, ZegoPublisherState, int, Map<String, dynamic>);
typedef PlayerStateUpdateCallback = void Function(String, ZegoPlayerState, int, Map<String, dynamic>);
typedef MediaPlayerPlayingProgressCallback = void Function(double);

class ZegoDelegate {

  RoomStateUpdateCallback? _onRoomStateUpdate;
  PublisherStateUpdateCallback? _onPublisherStateUpdate;
  PlayerStateUpdateCallback? _onPlayerStateUpdate;
  MediaPlayerPlayingProgressCallback? _onMediaPlayerPlayingProgress;

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

    ZegoExpressEngine.onMediaPlayerPlayingProgress = (ZegoMediaPlayer player, int progress) async {
      print('🚩 📥 media player preogress: $progress');
      _onMediaPlayerPlayingProgress?.call(progress/_totalDurationMediaplayer);
    }; 
  }

  void setZegoEventCallback(
    { RoomStateUpdateCallback? onRoomStateUpdate, 
      PublisherStateUpdateCallback? onPublisherStateUpdate,
      PlayerStateUpdateCallback? onPlayerStateUpdate,
      MediaPlayerPlayingProgressCallback? onMediaPlayerPlayingProgress,
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
    if (onMediaPlayerPlayingProgress != null)
    {
      _onMediaPlayerPlayingProgress = onMediaPlayerPlayingProgress;
    }
  }

  void clearZegoEventCallback() {
    _onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    
    _onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;

    _onPlayerStateUpdate = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;

    _onMediaPlayerPlayingProgress = null;
    ZegoExpressEngine.onMediaPlayerPlayingProgress = null;
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
      if ( _preViewID == -1)
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
          config: ZegoPlayerConfig(ZegoStreamResourceMode.Default, cdnConfig: cdnConfig, roomID: roomID));
      }
      else{
        ZegoExpressEngine.instance.startPlayingStream(streamID,);
      }

            print('📥 Start publish stream, streamID: $streamID');
    };

    if (streamID.isNotEmpty) {
      if ( _playViewID == -1 && needShow) {
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

  Future<Widget?> createPlatformView(Function(int) func,{int width = 360, int height = 640, }) async{
    Widget? widget = ZegoExpressEngine.instance.createPlatformView((viewID) {
          func(viewID);
    });
    return widget;
  }

  ZegoMediaPlayer? _mediaPlayer;
  int _totalDurationMediaplayer = 0;
  Future<Widget?> createMediaPlayer({int width = 360, int height = 640}) async {
    if (_mediaPlayer != null) {
      destroyMediaPlayer();
    }
     _mediaPlayer = await ZegoExpressEngine.instance.createMediaPlayer();

    return createPlatformView((viewID){
      _mediaPlayer?.setPlayerCanvas(ZegoCanvas(viewID));
    });

  }

  void destroyMediaPlayer() {
    if (_mediaPlayer != null) {
      ZegoExpressEngine.instance.destroyMediaPlayer(_mediaPlayer!);
    }
  }

  // 0 <= progress <=1
  Future<int> seekToMediaPlayer(double progress) async {
    int ret = -1;

    if (_mediaPlayer != null) {
      int millisecond = (_totalDurationMediaplayer*progress).toInt();
      var result = await _mediaPlayer!.seekTo(millisecond);
      ret = result.errorCode;
    }

    return ret;
  }

  Future<int> loadResourceMediaPlayer(String url) async{
    int ret = -1;
    if (_mediaPlayer != null) {
    var result = await _mediaPlayer!.loadResource(url);
        ret = result.errorCode;
    }
    if (ret == 0)
    {
      _totalDurationMediaplayer = await _mediaPlayer!.getTotalDuration();
    }

    return ret;
  }

  void startMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.start();
    }
  }

  void pauseMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.pause();
    }
  }

  void resumeMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.resume();
    }
  }

  void stopMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.stop();
    }
  }

  void setVolumeMediaPlayer(double volume) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.setVolume((200*volume).toInt());
    }
  }

  void repeatMediaPlayer(bool enable) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.enableRepeat(enable);
    }
  }

  void enableAuxMediaPlayer(bool enable) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.enableAux(enable);
    }
  }

  void muteLocalMediaPlayer(bool mute) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.muteLocal(mute);
    }
  }

  void setAudioTrackIndexMediaPlayer(int index) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.setAudioTrackIndex(index);
    }
  }

  void setVoiceChangerParamMediaPlayer(double value) {
    if (_mediaPlayer != null) {

      _mediaPlayer!.setVoiceChangerParam(ZegoMediaPlayerAudioChannel.All, ZegoVoiceChangerParam(value));
    }
  }

  void setPlaySpeedMediaPlayer(double speed) {
    if (_mediaPlayer != null) {
      _mediaPlayer!.setPlaySpeed(speed);
    }
  }
}