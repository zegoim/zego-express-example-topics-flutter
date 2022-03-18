import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class VoiceChangePage extends StatefulWidget {
  const VoiceChangePage({ Key? key }) : super(key: key);

  @override
  _VoiceChangePageState createState() => _VoiceChangePageState();
}

class _VoiceChangePageState extends State<VoiceChangePage> {

  static const _roomID = 'voice_change';
  static const _streamID = 'voice_change_s';

  late ZegoRoomState _roomState;
  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  late bool _encoderStereo;
  late ZegoAudioCaptureStereoMode _audioCaptureStereoMode;
  late bool _backgroundMusic;

  // voice changed

  late ZegoVoiceChangerPreset _changerPreset;
  late bool _changerCustomParam;
  late double _pitch;
  late bool _changerPresetEnable;
  late bool _pitchEnable;

  // reverb

  late ZegoReverbPreset _reverb;
  late bool _reverbCustomParam;
  late double _roomSize;
  late double _dampping;
  late double _reverberance;
  late bool _wetOnly;
  late double _wetGain;
  late double _dryGain;
  late double _toneLow;
  late double _toneHigh;
  late double _preDelay;
  late double _stereoWidth;

  late bool _reverbEnable;
  late bool _roomSizeEnable;
  late bool _damppingEnable;
  late bool _reverberanceEnable;
  late bool _wetOnlyEnable;
  late bool _wetGainEnable;
  late bool _dryGainEnable;
  late bool _toneLowEnable;
  late bool _toneHighEnable;
  late bool _preDelayEnable;
  late bool _stereoWidthEnable;

  // reverb echo
  late ZegoReverbEchoParam _reverbEchoParam;
  late ZegoReverbEchoParam _echoParamEthereal;
  late ZegoReverbEchoParam _echoParamRobot;
  late ZegoReverbEchoParam _echoParamNone;

  // vitualStereo
  late bool _vitualStereo;
  late double _angle;
  late bool _angleEnable;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  ZegoMediaPlayer? _mediaPlayer;

  late ZegoReverbAdvancedParam _advancedParam;

  late ZegoDelegate _zegoDelegate;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();

    _roomState =  ZegoRoomState.Disconnected;
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;

    _encoderStereo = false;
    _audioCaptureStereoMode = ZegoAudioCaptureStereoMode.None;
    _backgroundMusic = false;

    _changerPreset = ZegoVoiceChangerPreset.None;
    _changerCustomParam = false;
    _pitch = 0.0;
    _pitchEnable = false;
    _changerPresetEnable = true;

    _reverb = ZegoReverbPreset.None;
    _reverbCustomParam = false;
    _roomSize = 0;
    _dampping = 0;
    _reverberance = 0;
    _wetGain = 0;
    _wetOnly = false;
    _dryGain = 0;
    _toneLow = 1;
    _toneHigh = 1;
    _preDelay = 0;
    _stereoWidth = 0;

    _reverbEnable = true;
    _roomSizeEnable = false;
    _damppingEnable = false;
    _reverberanceEnable = false;
    _wetOnlyEnable = false;
    _wetGainEnable = false;
    _dryGainEnable = false;
    _toneLowEnable = false;
    _toneHighEnable = false;
    _preDelayEnable = false;
    _stereoWidthEnable = false;

    // reverberation echo
    _echoParamEthereal = ZegoReverbEchoParam(0.8,1.0,7,[230,460,690,920,1150,1380,1610], [0.41,0.18,0.08,0.03,0.009,0.003,0.001]);
    _echoParamRobot = ZegoReverbEchoParam(0.8, 1.0, 7, [60,210,180,240,300,360,420], [0.51,0.26,0.12,0.05,0.02,0.009,0.001]);
    _echoParamNone = ZegoReverbEchoParam(1, 1.0, 0, [0,0,0,0,0,0,40], [0.0,0.0,0.0,0.0,0.0,0.0,0.0]);
    _reverbEchoParam = _echoParamNone;

    _vitualStereo = false;
    _angle = 91;
    _angleEnable = false;

    _advancedParam = ZegoReverbAdvancedParam(_roomSize, _reverberance, _dampping, _wetOnly, _wetGain, _dryGain, _toneLow, _toneHigh, _preDelay, _stereoWidth);

    _zegoDelegate.setZegoEventCallback(onRoomStateUpdate: onRoomStateUpdate, onPublisherStateUpdate: onPublisherStateUpdate, onPlayerStateUpdate: onPlayerStateUpdate);
    _zegoDelegate.createEngine(enablePlatformView: true).then((value) async{
      await _zegoDelegate.loginRoom(_roomID);
      _mediaPlayer = await _zegoDelegate.createMediaPlayer();
      _mediaPlayer?.enableRepeat(true);
      _mediaPlayer?.loadResource('https://storage.zego.im/demo/sample_astrix.mp3');
    });

    
  }

  @override
  void dispose() {
    _zegoDelegate.clearZegoEventCallback();
    if (_mediaPlayer != null) {
      _zegoDelegate.destroyMediaPlayer(_mediaPlayer!);
    } 
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

  void onPublisherStateUpdate(String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
    if (streamID == _streamID) {
      setState(() {
        _publisherState = state;
      });
    }
  }

  void onPlayerStateUpdate(String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData) {
    if (streamID == _streamID) {
      setState(() {
        _playerState = state;
      });
    } 
  }

  // widget callback

  void onPublishBtnPress() {
    if (_publisherState == ZegoPublisherState.Publishing) {
      _zegoDelegate.stopPublishing();
    } else {
      _zegoDelegate.startPublishing(_streamID,enablePlatformView: true).then((widget) {
        setState(() {
          _previewViewWidget = widget;
        });
      });
    }
  }

  void onPlayBtnPress() {
    if (_playerState == ZegoPlayerState.Playing) {
      _zegoDelegate.stopPlaying(_streamID);
    } else {
      _zegoDelegate.startPlaying(_streamID,enablePlatformView: true).then((widget) {
        setState(() {
          _playViewWidget = widget;
        });
      });
    }
  }

  void onEncoderStereoSwitchChanged(bool b) {
    setState(() {
      _encoderStereo = b;
    });
    _zegoDelegate.setAudioConfig(ZegoAudioConfig.preset(b? ZegoAudioConfigPreset.StandardQualityStereo:ZegoAudioConfigPreset.StandardQuality));
  }

  void onCaptureStereoBtnChanged(ZegoAudioCaptureStereoMode? mode) {
    if (mode != null) {
      setState(() {
        _audioCaptureStereoMode = mode;
      });
      _zegoDelegate.setAudioCaptureStereoMode(mode);
    }
  }

  void onBackgroundMusicSwitchChanged(bool b) {
    setState(() {
      _backgroundMusic = b;
    });
    if (b) {
      _mediaPlayer?.start();
    } else {
      _mediaPlayer?.stop();
    }
  }

  void onVoiceChangerPreset(ZegoVoiceChangerPreset? mode) {
    if (mode != null) {
      setState(() {
        _changerPreset = mode;
      });
      _zegoDelegate.setVoiceChangerPreset(mode);
    }
  }

  void onChangerCustomParamSwitchChanged(bool b) {
    setState(() {
      _changerCustomParam = b;
      _changerPresetEnable = !_changerCustomParam;
      _pitchEnable = _changerCustomParam;
    });

    if (b) {
      _zegoDelegate.setVoiceChangerParam(ZegoVoiceChangerParam(_pitch));
    } else {
      _zegoDelegate.setVoiceChangerPreset(_changerPreset);
    }
  }

  void onPitchChanged(double value) {
    setState(() {
      _pitch = value;
      _zegoDelegate.setVoiceChangerParam(ZegoVoiceChangerParam(_pitch));
    });
  }

  void onReverbBtnChanged(ZegoReverbPreset? preset) {
    if (preset != null) {
      setState(() {
        _reverb = preset;
      });
      _zegoDelegate.setReverbPreset(preset);
    }
  }

  void onReverbCustomParamSwitchChanged(bool b) {
    setState(() {
      _reverbCustomParam = b;

      _reverbEnable = !_reverbCustomParam;
      _roomSizeEnable = _reverbCustomParam;
      _damppingEnable = _reverbCustomParam;
      _reverberanceEnable = _reverbCustomParam;
      _wetOnlyEnable = _reverbCustomParam;
      _wetGainEnable = _reverbCustomParam;
      _dryGainEnable = _reverbCustomParam;
      _toneLowEnable = _reverbCustomParam;
      _toneHighEnable = _reverbCustomParam;
      _preDelayEnable = _reverbCustomParam;
      _stereoWidthEnable = _reverbCustomParam;
    });
    if (b) {
      _zegoDelegate.setReverbAdvancedParam(_advancedParam);
    } else {
      _zegoDelegate.setReverbPreset(_reverb);
    }
  }

  void onRoomSizeChanged(double value) {
    setState(() {
      _roomSize = value;
    });
    _advancedParam.roomSize = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onDamppingChanged(double value) {
    setState(() {
      _dampping = value;
    });
    _advancedParam.damping = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onReverberanceChanged(double value) {
    setState(() {
      _reverberance = value;
    });
    _advancedParam.reverberance = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }
  

  void onWetGainChanged(double value) {
    setState(() {
      _wetGain = value;
    });
    _advancedParam.wetGain = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onWetOnlySwitchChanged(bool b) {
    setState(() {
      _wetOnly = b;
    });
    _advancedParam.wetOnly= b;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onDryGainChanged(double value) {
    setState(() {
      _dryGain = value;
    });
    _advancedParam.dryGain = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onPreDelayChanged(double value) {
    setState(() {
      _preDelay = value;
    });
    _advancedParam.preDelay = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onStereoWidthChanged(double value) {
    setState(() {
      _stereoWidth = value;
    });
    _advancedParam.stereoWidth = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onToneHighChanged(double value) {
    setState(() {
      _toneHigh = value;
    });
    _advancedParam.toneHigh = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }

  void onToneLowChanged(double value) {
    setState(() {
      _toneLow = value;
    });
    _advancedParam.toneLow = value;
    _zegoDelegate.setReverbAdvancedParam(_advancedParam);
  }
  
  void onReverbEchoParamBtnChanged(ZegoReverbEchoParam? param) {
    if (param != null) {
      setState(() {
        _reverbEchoParam = param;
      });
      _zegoDelegate.setReverbEchoParam(param);
    }  
  }

  void onVitualStereoSwitchChanged(bool b) {
    setState(() {
      _vitualStereo = b;
      _angleEnable = _vitualStereo;
    });
    _zegoDelegate.enableVirtualStereo(b, _angle.toInt());
  }

  void onAngleChanged(double value) {
    setState(() {
      _angle = value;
    });
    _zegoDelegate.enableVirtualStereo(_angleEnable, value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('变声、混响、立体声'),),
      body: SafeArea(child: SingleChildScrollView(child: mainContent(context),)),
    );
  }

  Widget mainContent(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          roomInfoWidget(),
          viewWidget(context),
          voiceChangedWidget(context),
          reverberationWidget(context),
          reverbEchoWidget(context),
          vitualStereoWidget(context)
        ],
      ),
    );
  }

  Widget roomInfoWidget() {
    return Container(
        padding: EdgeInsets.all(10),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RoomID: $_roomID"),
          Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}'),
          Text('StreamID: $_streamID')
        ]
      )
    );
  }

  Widget viewWidget(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height*0.3,
            child: GridView(
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 3/4,
              ),
              children: [
                Stack(
                  children: [
                    Container(
                      color: Colors.grey[300],
                      child: _previewViewWidget,
                    ),
                  preWidgetTopWidget()
                  ], 
                  alignment: AlignmentDirectional.topCenter,
                ),
                Stack(
                  children: [
                    Container(
                      color: Colors.grey[300],
                      child:  _playViewWidget,
                    ),
                    playWidgetTopWidget()
                  ], 
                  alignment: AlignmentDirectional.topCenter,
                ),
              ],
            )
          )
        ],
      ),
    );
  }

  Widget voiceChangedWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(10),
          color: Colors.grey,
          child: Text('变声', style: TextStyle(fontSize: 18)),
        ),
        Container(
          padding: EdgeInsets.only(left: 10,right: 10, bottom: 10),
          height: MediaQuery.of(context).size.height*0.1,
          child: GridView(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 5/1,
            ),
            children: [
              Row(
                children: [
                  Expanded(child: Text('预设')),
                  DropdownButton(
                    value: _changerPreset, 
                    onChanged: onVoiceChangerPreset,
                    items: _changerPresetEnable? ZegoVoiceChangerPreset.values.map<DropdownMenuItem<ZegoVoiceChangerPreset>>((value){
                      return DropdownMenuItem<ZegoVoiceChangerPreset>(child: Text('${value.toString().replaceAll('ZegoVoiceChangerPreset.', '')}'),value: value,);
                    }).toList(): <DropdownMenuItem<ZegoVoiceChangerPreset>>[]
                  ),
                ]
              ),
              Row(
                children: [
                  Expanded(child: Text('自定义参数')),
                  Switch(value: _changerCustomParam, onChanged: onChangerCustomParamSwitchChanged),
                ]
              ),
              Row(
                children: [
                  Text('音高'),
                  Expanded(child: customSlider(value: _pitch, onChanged: onPitchChanged, min: -8.0, max: 8.0, enable: _pitchEnable)),
                ]
              ),
            ],
          )
        )
      ]
    );
  }

  Widget reverberationWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(10),
          color: Colors.grey,
          child: Text('混响', style: TextStyle(fontSize: 18)),
        ),
        Container(
          padding: EdgeInsets.only(left: 10,right: 10, bottom: 10),
          height: MediaQuery.of(context).size.height*0.30,
          child: GridView(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 5.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 5/1,
            ),
            children: [
              Row(
                children: [
                  Expanded(child: Text('预设', style: TextStyle(fontSize: 12))),
                  DropdownButton(
                    value: _reverb, 
                    onChanged: onReverbBtnChanged,
                    items: _reverbEnable? ZegoReverbPreset.values.map<DropdownMenuItem<ZegoReverbPreset>>((value){
                      return DropdownMenuItem<ZegoReverbPreset>(child: Text('${value.toString().replaceAll('ZegoReverbPreset.', '')}'),value: value,);
                    }).toList() :<DropdownMenuItem<ZegoReverbPreset>>[]
                  ),
                ]
              ),
              Row(
                children: [
                  Expanded(child: Text('自定义参数', style: TextStyle(fontSize: 12))),
                  Switch(value: _reverbCustomParam, onChanged: onReverbCustomParamSwitchChanged),
                ]
              ),
              Row(
                children: [
                  Text('房间大小', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _roomSize, onChanged: onRoomSizeChanged, max: 1.0, enable: _roomSizeEnable)),
                ]
              ),
              Row(
                children: [
                  Text('余响', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _dampping, onChanged: onDamppingChanged, max: 100.0, enable: _damppingEnable)),
                ]
              ),
              Row(
                children: [
                  Text('混响阻尼', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _reverberance, onChanged: onReverberanceChanged, max: 100.0, enable: _reverberanceEnable)),
                ]
              ),
              Row(
                children: [
                  Expanded(child: Text('只有湿信号', style: TextStyle(fontSize: 12))),
                  Switch(value: _wetOnly, onChanged: _wetOnlyEnable?onWetOnlySwitchChanged: null),
                ]
              ),
              Row(
                children: [
                  Text('湿信号增益', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _wetGain, onChanged: onWetGainChanged, min: -20.0, max: 10.0, enable: _wetGainEnable)),
                ]
              ),
              Row(
                children: [
                  Text('干信号增益', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _dryGain, onChanged: onDryGainChanged, min: -20.0, max: 10.0, enable: _dryGainEnable)),
                ]
              ),
              Row(
                children: [
                  Text('低频衰弱', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _toneLow, onChanged: onToneLowChanged, max: 1.0, enable: _toneLowEnable)),
                ]
              ),
              Row(
                children: [
                  Text('高频衰弱', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _toneHigh, onChanged: onToneHighChanged, max: 1.0, enable: _toneHighEnable)),
                ]
              ),
              Row(
                children: [
                  Text('初始延迟时间', style: TextStyle(fontSize: 12)),
                  Expanded(child: customSlider(value: _preDelay, onChanged: onPreDelayChanged, max: 200.0, enable: _preDelayEnable)),
                ]
              ),
              Row(
                children: [
                  Text('立体声宽度', style: TextStyle(fontSize: 12),),
                  Expanded(child: customSlider(value: _stereoWidth, onChanged: onStereoWidthChanged, max: 1.0, enable: _stereoWidthEnable)),
                ]
              ),
            ],
          )
        )
      ]
    );
  }

  Widget reverbEchoWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(10),
          color: Colors.grey,
          child: Text('混响回声', style: TextStyle(fontSize: 18)),
        ),
        Container(
          padding: EdgeInsets.only(left: 10,right: 10, bottom: 10),
          height: MediaQuery.of(context).size.height*0.05,
          child: Row(
            children: [
              Expanded(child: Text('预设')),
              DropdownButton(
                value: _reverbEchoParam, 
                onChanged: onReverbEchoParamBtnChanged,
                items: [
                  DropdownMenuItem<ZegoReverbEchoParam>(child: Text('NONE'),value: _echoParamNone,),
                  DropdownMenuItem<ZegoReverbEchoParam>(child: Text('Robot'),value: _echoParamRobot,),
                  DropdownMenuItem<ZegoReverbEchoParam>(child: Text('Ethereal'),value: _echoParamEthereal,),
                ]
              ),
            ]
          ),
        )
      ]
    );
  }

  Widget vitualStereoWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(10),
          color: Colors.grey,
          child: Row(children: [
            Text('虚拟立体声', style: TextStyle(fontSize: 18)),
            Switch(value: _vitualStereo, onChanged: onVitualStereoSwitchChanged)
          ],) 
        ),
        Container(
          padding: EdgeInsets.only(left: 10,right: 10, bottom: 10),
          height: MediaQuery.of(context).size.height*0.05,
          child: Row(
            children: [
              Text('声浪角度'),
              Expanded(child: customSlider(value: _angle, onChanged: onAngleChanged, max: 361.0, enable: _angleEnable)),
            ]
          ),
        )
      ]
    );
  }

  // Buttons and titles on the preview widget
  Widget preWidgetTopWidget() {
    return Padding(padding: EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('Local Preview View', 
            style: TextStyle(color: Colors.white))),
        Expanded(child: Container()),
        Row(
          children: [
            Expanded(child: Text('Encoder Stereo', style: TextStyle(fontSize: 12))),
            Switch(value: _encoderStereo, onChanged: onEncoderStereoSwitchChanged)
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Capture Stereo', style: TextStyle(fontSize: 12))),
            DropdownButton(
              value: _audioCaptureStereoMode, 
              onChanged: onCaptureStereoBtnChanged,
              items: [
                DropdownMenuItem(child: Text('None', style: TextStyle(fontSize: 12)),value: ZegoAudioCaptureStereoMode.None,),
                DropdownMenuItem(child: Text('Always', style: TextStyle(fontSize: 12)),value: ZegoAudioCaptureStereoMode.Always,),
                DropdownMenuItem(child: Text('Adaptive', style: TextStyle(fontSize: 12)),value: ZegoAudioCaptureStereoMode.Adaptive,),
              ]
            )
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Background Music', style: TextStyle(fontSize: 12))),
            Switch(value: _backgroundMusic, onChanged: onBackgroundMusicSwitchChanged)
          ],
        ),
        Container(
          padding: EdgeInsets.only(left: 10),
          width: MediaQuery.of(context).size.width*0.4,
          child:CupertinoButton.filled(
            child: Text(_publisherState == ZegoPublisherState.Publishing ? '✅ StopPublishing' : 'StartPublishing', 
              style: TextStyle(fontSize: 14.0),),
            onPressed: onPublishBtnPress,
            padding: EdgeInsets.all(10.0)
          )
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
        Expanded(child: Container()),
        Container(
          padding: EdgeInsets.only(left: 10),
          width: MediaQuery.of(context).size.width*0.4,
          child: CupertinoButton.filled(
            child: Text(_playerState == ZegoPlayerState.Playing ? '✅ StopPlaying' : 'StartPlaying', 
              style: TextStyle(fontSize: 14.0),),
            onPressed: onPlayBtnPress,
            padding: EdgeInsets.all(10.0)
          ),
        )
      ]
    ));
  }

  // custom widget
  Widget customSlider({required double value, required Function(double)? onChanged, double max = 100.0, double min = 0.0, bool enable = true}) {
    return Slider(value: value, onChanged: enable?onChanged: null, max: max, min: 0.0, activeColor: enable? Colors.blue: Colors.grey, inactiveColor: enable?Colors.blue[100]: Colors.grey,);
  }
}


typedef RoomStateUpdateCallback = void Function(String, ZegoRoomState, int, Map<String, dynamic>);
typedef PublisherStateUpdateCallback = void Function(String, ZegoPublisherState, int, Map<String, dynamic>);
typedef PlayerStateUpdateCallback = void Function(String, ZegoPlayerState, int, Map<String, dynamic>);

class ZegoDelegate {

  RoomStateUpdateCallback? _onRoomStateUpdate;
  PublisherStateUpdateCallback? _onPublisherStateUpdate;
  PlayerStateUpdateCallback? _onPlayerStateUpdate;

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
  }

  void setZegoEventCallback(
    { RoomStateUpdateCallback? onRoomStateUpdate, 
      PublisherStateUpdateCallback? onPublisherStateUpdate,
      PlayerStateUpdateCallback? onPlayerStateUpdate,
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
  }

  void clearZegoEventCallback() {
    _onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    
    _onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;

    _onPlayerStateUpdate = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;
  }

  void getEngineConfig() {
      ZegoExpressEngine.getVersion().then((value) => print('🌞 SDK Version: $value'));
    }

  void enableCamare(bool enable) {
    ZegoExpressEngine.instance.enableCamera(enable);
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


  Future<void> setRoomMode(ZegoRoomMode mode) {
    return ZegoExpressEngine.setRoomMode(mode);
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

  Future<ZegoMediaPlayer?> createMediaPlayer({int width = 360, int height = 640}) async {
    return await ZegoExpressEngine.instance.createMediaPlayer();
  }

  void destroyMediaPlayer(ZegoMediaPlayer mediaPlayer) {
    ZegoExpressEngine.instance.destroyMediaPlayer(mediaPlayer);
  }

  void setAudioConfig(ZegoAudioConfig config) {
    ZegoExpressEngine.instance.setAudioConfig(config);
  }

  void setAudioCaptureStereoMode(ZegoAudioCaptureStereoMode mode) {
    ZegoExpressEngine.instance.setAudioCaptureStereoMode(mode);
  }

  void setVoiceChangerPreset(ZegoVoiceChangerPreset preset) {
    ZegoExpressEngine.instance.setVoiceChangerPreset(preset);
  }

  void setVoiceChangerParam(ZegoVoiceChangerParam param) {
    ZegoExpressEngine.instance.setVoiceChangerParam(param);
  }

  void setReverbPreset(ZegoReverbPreset preset) {
    ZegoExpressEngine.instance.setReverbPreset(preset);
  }

  void setReverbAdvancedParam(ZegoReverbAdvancedParam param) {
    ZegoExpressEngine.instance.setReverbAdvancedParam(param);
  }

  void setReverbEchoParam(ZegoReverbEchoParam param) {
    ZegoExpressEngine.instance.setReverbEchoParam(param);
  }

  void enableVirtualStereo(bool enable, int angle) {
    ZegoExpressEngine.instance.enableVirtualStereo(enable, angle);
  }
}