import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class PublishStreamSettingsPage extends StatefulWidget {

  @override
  _PublishStreamSettingsPageState createState() => new _PublishStreamSettingsPageState();
}

class _PublishStreamSettingsPageState extends State<PublishStreamSettingsPage> {

  static bool _isPreviewMirror = true;
  static bool _isPublishMirror = false;
  static bool _enableHardwareEncoder = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void checkMirrorMode() {

    if (!_isPreviewMirror && !_isPublishMirror) {

      ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);

    } else if (!_isPreviewMirror && _isPublishMirror) {

      ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.OnlyPublishMirror);

    } else if (_isPreviewMirror && !_isPublishMirror) {

      ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.OnlyPreviewMirror);

    } else {

      ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);

    }
  }

  void onPreviewMirrorValueChanged(bool value) {
    setState(() {
      _isPreviewMirror = value;
      checkMirrorMode();
    });
  }

  void onPublishMirrorValueChanged(bool value) {
    setState(() {
      _isPublishMirror = value;
      checkMirrorMode();
    });
  }

  void onEnableHardwareEncodeValueChanged(bool value) {
    setState(() {
      _enableHardwareEncoder = value;
      ZegoExpressEngine.instance.enableHardwareEncoder(_enableHardwareEncoder);
    });
  }

  Widget setMirrorModeRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black26
          )
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'Video Mirror Mode',
            style: TextStyle(
              fontSize: 15.0
            ),
          ),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Preview Mirror',
                    style: TextStyle(
                      fontSize: 12.0
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isPreviewMirror,
                    onChanged: onPreviewMirrorValueChanged,
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Text(
                    'Publish Mirror',
                    style: TextStyle(
                      fontSize: 12.0
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isPublishMirror,
                    onChanged: onPublishMirrorValueChanged,
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget enableHardwareEncodeRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black26
          )
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'Hardware Encoder',
            style: TextStyle(
              fontSize: 15.0
            ),
          ),
          Padding(padding: EdgeInsets.all(15)),
          Expanded(
            child: Text(
              '(The setting only valid before start publishing stream)',
              style: TextStyle(
                fontSize: 10.0
              ),),
          ),
          CupertinoSwitch(
            value: _enableHardwareEncoder,
            onChanged: onEnableHardwareEncodeValueChanged,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            /// Video Mirror Mode
            setMirrorModeRow(),
            enableHardwareEncodeRow(),
          ],
        ),
      ),
    );
  }

}