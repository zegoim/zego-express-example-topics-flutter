import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/stream_mixing/auto_mixer.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/stream_mixing/mixer_publish.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/stream_mixing/mixer_start.dart';

class MixerMainPage extends StatelessWidget {
  const MixerMainPage({ Key? key }) : super(key: key) ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("混流"),),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.15), 
                child: Text('使用说明:', style: TextStyle(color: Colors.blue[200]),)),
              Container(
                width: MediaQuery.of(context).size.width*0.7,
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.03, bottom: MediaQuery.of(context).size.height*0.05), 
                child: Text('本专题需要使用三台设备进行体验，其中两台设备发起推流，使用另外一台设备发起混流并观看', softWrap: true,),),
              Text('RoomID:    mixer'),
              Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.02),
                child: SizedBox( width: MediaQuery.of(context).size.width*0.7, 
                  child: CupertinoButton.filled(
                    child: Text('发起推流',),
                    onPressed: () => onPublishingBtnPress(context),
                    padding: EdgeInsets.only(top:10, bottom: 10)
                  )
                ),
              ),
              Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01),
                child: SizedBox( width: MediaQuery.of(context).size.width*0.7, 
                  child: CupertinoButton.filled(
                    child: Text('发起混流',),
                    onPressed: () => onMixerBtnPress(context),
                    padding: EdgeInsets.only(top:10, bottom: 10)
                  ),
                )
              ),
              Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01),
                child: SizedBox( width: MediaQuery.of(context).size.width*0.7, 
                  child: CupertinoButton.filled(
                    child: Text('发起自动混流',),
                    onPressed: () => onAutoMixerBtnPress(context),
                    padding: EdgeInsets.only(top:10, bottom: 10)
                  ),
                )
              ),
            ],
          ),
        )
      )
    );
  }

  void onPublishingBtnPress(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return MixerPublishPage();
    }));
  }

  void onMixerBtnPress(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return MixerStartPage();
    }));
  }

  void onAutoMixerBtnPress(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return AutoMixerPage();
    }));
  }
}