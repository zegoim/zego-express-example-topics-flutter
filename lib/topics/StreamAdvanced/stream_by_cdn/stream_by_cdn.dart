import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/topics/StreamAdvanced/stream_by_cdn/direct_publishing_to_cdn_activity.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class AddStreamToCDNPage extends StatefulWidget {
  const AddStreamToCDNPage({Key? key }) : super(key: key);
  @override
  _AddStreamToCDNPageState createState() => _AddStreamToCDNPageState();
}

class _AddStreamToCDNPageState extends State<AddStreamToCDNPage> {

  late ZegoRoomState _roomState;
  final String _roomID = "stream_by_cdn";
  final String _streamID = "stream_by_cdn";
  static const double viewRatio = 3.0/4.0;

  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  late TextEditingController _publishCdnUrlController;
  late TextEditingController _playCdnUrlController;

  late bool _isPublishCdn;

  late ZegoDelegate _zegoDelegate;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();
    
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;
    _roomState = ZegoRoomState.Disconnected;

    _publishCdnUrlController = TextEditingController();

    _playCdnUrlController = TextEditingController();

    _isPublishCdn = false;

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate:onRoomStateUpdate, 
        onPublisherStateUpdate:onPublisherStateUpdate, 
        onPlayerStateUpdate:onPlayerStateUpdate,
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

  @override
  void deactivate() {
    super.deactivate();
    print('deactivate');
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

  void onPublishStreamBtnPress() {
    if (_publisherState != ZegoPublisherState.Publishing )
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
      if (_playCdnUrlController.text.isNotEmpty) {
        _zegoDelegate.startPlaying(_streamID, enablePlatformView: true, cdnURL: _playCdnUrlController.text).then((widget) {
          setState(() {
            _playViewWidget = widget;
          });
        });
      }
      
    }
    else{
      _zegoDelegate.stopPlaying(_streamID);
    }
  }

  void onPublishByCdnBtnPress() {
    if (_publishCdnUrlController.text.isNotEmpty)
    {
      if (!_isPublishCdn) {
        _zegoDelegate.addPublishCdnUrl(_streamID, _publishCdnUrlController.text);
      } else {
        _zegoDelegate.removePublishCdnUrl(_streamID, _publishCdnUrlController.text);
        _zegoDelegate.stopPublishing();
      }
    }

    setState(() {
      _isPublishCdn = !_isPublishCdn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("通过CDN推流、拉流"),),
      body: SafeArea(child: 
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              roomInfoWidget(context),
              streamViewsWidget(),
              publishStreamByCdnWidget(),
              playStreamByCdnWidget(),
              bottomJumpCDNWidget()
            ],
          ),
        )
      ),
    );
  }

  Widget roomInfoWidget(context) {
    return Padding(padding: EdgeInsets.only(left: 10), 
      child:  
        Text('RoomID: $_roomID UserID: ${ZegoConfig.instance.userID} \nRoomState: ${_zegoDelegate.roomStateDesc(_roomState)}')
    );
  }

  Widget publishStreamByCdnWidget() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('转推CDN ', style: TextStyle(fontSize: 18, color: Colors.black)),
            Text('将音视频流从Zego实时音视频云转推到CDN', style: TextStyle(fontSize: 12, color: Colors.black38)),
            Padding(padding: EdgeInsets.only(top: 10)),
            Row(
              children: [
                Expanded(child:RichText(text: TextSpan(children: <InlineSpan>[
                  TextSpan(text: 'Step1 ', style: TextStyle(fontSize: 18, color: Colors.black)),
                  TextSpan(text: '开始推流', style: TextStyle(fontSize: 16, color: Colors.black38))
                ]))),           
                CupertinoButton.filled(
                  child: Text(
                    _publisherState == ZegoPublisherState.Publishing ? '✅ 停止推流' : '开始推流', 
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: onPublishStreamBtnPress,
                  padding: EdgeInsets.all(10.0)
                ),   
              ],
            ),
            Padding(padding: EdgeInsets.only(top: 10)),
            Row(
              children: [
                Text('推流 CDN URL ', style: TextStyle(fontSize: 14, color: Colors.black)),
                Expanded(child: TextField(
                  controller: _publishCdnUrlController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10.0),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                  ),
                ))
              ]
            ),
            Padding(padding: EdgeInsets.only(top: 10)),
            Row(
              children: [
                Expanded(child:RichText(text: TextSpan(children: <InlineSpan>[
                  TextSpan(text: 'Step2 ', style: TextStyle(fontSize: 18, color: Colors.black)),
                  TextSpan(text: '添加CDN URL', style: TextStyle(fontSize: 16, color: Colors.black38))
                ]))),           
                CupertinoButton.filled(
                  child: Text(
                    _isPublishCdn ? '停止转推CDN' : '添加推流到CDN的URL', 
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: onPublishByCdnBtnPress,
                  padding: EdgeInsets.all(10.0)
                ),   
              ],
            ),
          ],
        )
      ,)
    );
  }
  
  Widget playStreamByCdnWidget() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('从 URL 拉流 ', style: TextStyle(fontSize: 18, color: Colors.black)),
            Padding(padding: EdgeInsets.only(top: 10)),
            Row(
              children: [
                Text('CDN URL ', style: TextStyle(fontSize: 14, color: Colors.black)),
                Expanded(child: TextField(
                  controller: _playCdnUrlController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10.0),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                  ),
                ))
              ]
            ),
            Padding(padding: EdgeInsets.only(top: 10)),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CupertinoButton.filled(
              child: Text(
                _playerState == ZegoPlayerState.Playing ? '✅ 停止拉流' : '从 URL 拉流', 
                style: TextStyle(fontSize: 14.0),
              ),
              onPressed: onPlayStreamBtnPress,
              padding: EdgeInsets.all(10.0)
            )),  
          ],
        )
      ,)
    );
  }

  // Buttons and titles on the preview widget
  Widget preWidgetTopWidget() {
    return Padding(padding: EdgeInsets.only(top: 10),
      child: Text('Local Preview View', 
          style: TextStyle(color: Colors.white)),
      );
  }

  // Buttons and titles on the play widget
  Widget playWidgetTopWidget() {
    return Padding(padding: EdgeInsets.only(top: 10),
      child: Text('Remote Play View', 
            style: TextStyle(color: Colors.white)));
  }

  Widget streamViewsWidget() {
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
        ],
        ));
  }

  Widget bottomJumpCDNWidget() {
    return Center(
      child: Column(
        children: [
          TextButton(child: Text('直推CDN >', style: TextStyle(fontSize: 18)), onPressed: () async{
            await _zegoDelegate.logoutRoom(_roomID);

            _zegoDelegate.clearZegoEventCallback();
        
            _zegoDelegate.destroyEngine();
            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
              return DirectPublishingToCDNActivityPage();
            })).then((value){
              _zegoDelegate.setZegoEventCallback(
                  onRoomStateUpdate:onRoomStateUpdate, 
                  onPublisherStateUpdate:onPublisherStateUpdate, 
                  onPlayerStateUpdate:onPlayerStateUpdate,
                  );
              _zegoDelegate.createEngine(enablePlatformView: true).then((value) {
                _zegoDelegate.loginRoom(_roomID);
              });
              setState(() {
                _publisherState = ZegoPublisherState.NoPublish;
                _isPublishCdn = false;
                _playerState = ZegoPlayerState.NoPlay;
              });
            });
          },),
          Text('将音视频流直接从本地客户端直接推送到CDN', style: TextStyle(fontSize: 12, color: Colors.black38))
        ],
      ),
    );
  }
}
