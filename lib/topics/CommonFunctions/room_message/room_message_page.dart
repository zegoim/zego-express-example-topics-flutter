//
//  room_message_page.dart
//  flutter_dart
//
//  Created by Patrick Fu on 2021/07/11.
//  Copyright © 2021 Zego. All rights reserved.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';

class RoomMessageObject {
  String fromUserID = '';
  String message = '';
}

class RoomMessagePage extends StatefulWidget {
  @override
  _RoomMessagePageState createState() => _RoomMessagePageState();
}

class _RoomMessagePageState extends State<RoomMessagePage> {

  final String _roomID = '0007';

  String _messagesBuffer = '';

  bool _isEngineActive = false;
  ZegoRoomState _roomState = ZegoRoomState.Disconnected;

  List<ZegoUser> _allUsers = [];
  List<ZegoUser> _customCommandSelectedUsers = [];

  TextEditingController _broadcastMessageController = new TextEditingController();
  TextEditingController _customCommandController = new TextEditingController();
  TextEditingController _barrageMessageController = new TextEditingController();
  TextEditingController _roomExtraInfoKeyController = new TextEditingController();
  TextEditingController _roomExtraInfoValueController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    ZegoExpressEngine.getVersion().then((value) => print('🌞 SDK Version: $value'));

    createEngine();

    loginRoom();

    setZegoEventCallback();
  }

  @override
  void dispose() {

    destroyEngine();

    clearZegoEventCallback();

    super.dispose();
  }


  void createEngine() {
    ZegoEngineProfile profile = ZegoEngineProfile(
      ZegoConfig.instance.appID, 
      ZegoConfig.instance.appSign, 
      ZegoConfig.instance.scenario,
      enablePlatformView: ZegoConfig.instance.enablePlatformView);
    ZegoExpressEngine.createEngineWithProfile(profile);

    // Notify View that engine state changed
    setState(() => _isEngineActive = true);

    print('🚀 Create ZegoExpressEngine');
  }


  void loginRoom() {
    // Instantiate a ZegoUser object
    ZegoUser user = ZegoUser(ZegoConfig.instance.userID, ZegoConfig.instance.userName);

    // Login Room
    ZegoExpressEngine.instance.loginRoom(_roomID, user);

    print('🚪 Start login room, roomID: $_roomID');
  }

  // MARK: - Exit

  void destroyEngine() async {

    // Can destroy the engine when you don't need audio and video calls
    //
    // Destroy engine will automatically logout room and stop publishing/playing stream.
    ZegoExpressEngine.destroyEngine();

    print('🏳️ Destroy ZegoExpressEngine');

    // Notify View that engine state changed
    setState(() {
      _isEngineActive = false;
      _roomState = ZegoRoomState.Disconnected;
    });
  }

  // MARK: - Event

  void setZegoEventCallback() {
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      print('🚩 🚪 Room state update, roomID: $roomID, state: $state, errorCode: $errorCode');
      setState(() => _roomState = state);
    };

    ZegoExpressEngine.onRoomUserUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      print('🚩 🕺 Room user update, roomID: $roomID, type: ${updateType.toString()}, count: ${userList.length}');
      if (updateType == ZegoUpdateType.Add) {
        setState(() => _allUsers.addAll(userList));
      } else if (updateType == ZegoUpdateType.Delete) {
        for (ZegoUser removedUser in userList) {
          for (ZegoUser user in _allUsers) {
            if (user.userID == removedUser.userID && user.userName == removedUser.userName) {
              setState(() => _allUsers.remove(user));
            }
          }
        }
      }
    };

    ZegoExpressEngine.onIMRecvBroadcastMessage = (String roomID, List<ZegoBroadcastMessageInfo> messageList) {
      for (ZegoBroadcastMessageInfo message in messageList) {
        print('🚩 💬 Received broadcast message, ID: ${message.messageID}, fromUser: ${message.fromUser.userID}, sendTime: ${message.sendTime}, roomID: $roomID');
        appendMessage('💬 ${message.message} [ID:${message.messageID}] [From:${message.fromUser.userName}]');
      }

    };

    ZegoExpressEngine.onIMRecvCustomCommand = (String roomID, ZegoUser fromUser, String command) {
      print('🚩 💭 Received custom command, fromUser: ${fromUser.userID}, roomID: $roomID, command: $command');
      appendMessage('💭 $command [From:${fromUser.userName}]');
    };

    ZegoExpressEngine.onIMRecvBarrageMessage = (String roomID, List<ZegoBarrageMessageInfo> messageList) {
      for (ZegoBarrageMessageInfo message in messageList) {
        print('🚩 🗯 Received barrage message, ID: ${message.messageID}, fromUser: ${message.fromUser.userID}, sendTime: ${message.sendTime}, roomID: $roomID');
        appendMessage('🗯 ${message.message} [ID:${message.messageID}] [From:${message.fromUser.userName}]');
      }
    };

    ZegoExpressEngine.onRoomExtraInfoUpdate = (String roomID, List<ZegoRoomExtraInfo> roomExtraInfoList) {
      print('🚩 📢 Room extra info update');
      for (ZegoRoomExtraInfo info in roomExtraInfoList) {
        print('🚩 📢 --- Key: ${info.key}, Value: ${info.value}, Time: ${info.updateTime}, UserID: ${info.updateUser.userID}');
        appendMessage('📢 RoomExtraInfo: Key: [${info.key}], Value: [${info.value}], From:${info.updateUser.userName}');
      }
    };

  }

  void clearZegoEventCallback() {
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onIMRecvBroadcastMessage = null;
    ZegoExpressEngine.onIMRecvCustomCommand = null;
    ZegoExpressEngine.onIMRecvBarrageMessage = null;
  }

  // MARK: - Message

  void sendBroadcastMessage() {
    String message = _broadcastMessageController.text.trim();
    ZegoExpressEngine.instance.sendBroadcastMessage(_roomID, message).then((value) {
      print('🚩 💬 Send broadcast message result, errorCode: ${value.errorCode}');
      appendMessage('💬 📤 Sent: $message');
    });

  }

  void sendCustomCommand() {
    // TODO: Support selecting users
    _customCommandSelectedUsers = _allUsers;

    String command = _customCommandController.text.trim();
    ZegoExpressEngine.instance.sendCustomCommand(_roomID, command, _customCommandSelectedUsers).then((value) {
      print('🚩 💭 Send custom command result, errorCode: ${value.errorCode}');
      appendMessage('💭 📤 Sent: $command');
    });
  }

  void sendBarrageMessage() {
    String message = _barrageMessageController.text.trim();
    ZegoExpressEngine.instance.sendBarrageMessage(_roomID, message).then((value) {
      print('🚩 🗯 Send barrage message, errorCode: ${value.errorCode}');
      appendMessage('🗯 📤 Sent: $message');
    });
  }

  void setRoomExtraInfo() {
    String key = _roomExtraInfoKeyController.text.trim();
    String value = _roomExtraInfoValueController.text.trim();
    ZegoExpressEngine.instance.setRoomExtraInfo(_roomID, key, value).then((result) {
      print('🚩 📢 Set room extra info result, errorCode: ${result.errorCode}');
      appendMessage('📢 📤 Set: key: $key, value: $value');
    });
  }

  void appendMessage(String message) {
    setState(() {
      _messagesBuffer = '$_messagesBuffer[${DateTime.now().toLocal().toString()}] $message\n\n\n';
    });
  }

  // MARK: - Widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RoomMessage')),
      body: SafeArea(child: GestureDetector(
        child: mainContent(),
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      )),
    );
  }

  Widget mainContent() {
    return SingleChildScrollView(child: Column(children: [
      Divider(),

      Container(
        child: roomInfoWidget(),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3)
      ),
      Divider(),

      sendBroadcastMessageWidget(),
      Divider(),

      sendCustomCommandWidget(),
      Divider(),

      sendBarrageMessageWidget(),
      Divider(),

      setRoomExtraInfoWidget(),
      Divider(),

      Text(_messagesBuffer, textAlign: TextAlign.left),

    ]));
  }

  Widget sendBroadcastMessageWidget() {
    return sendMessageWidget('💬 Broadcast Message', 'Send to all users', _broadcastMessageController, sendBroadcastMessage, Spacer());
  }

  Widget sendCustomCommandWidget() {
    // TODO: Support selecting users, add a button here
    return sendMessageWidget('💭 Custom Command', 'Send to specified users', _customCommandController, sendCustomCommand, Spacer());
  }

  Widget sendBarrageMessageWidget() {
    return sendMessageWidget('🗯 Barrage Message', 'Send to all users', _barrageMessageController, sendBarrageMessage, Spacer());
  }

  Widget sendMessageWidget(String labelText, String hintText, TextEditingController textController, VoidCallback sendFunction, Widget extraWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(children: [
            Text(labelText, style: TextStyle(fontSize: 15),),
            extraWidget,
          ],),
          SizedBox(height: 5),
          Row(children: [
            Expanded(child: TextField(
              controller: textController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                isDense: true,
                // labelText: labelText,
                // labelStyle: TextStyle(color: Colors.black54, fontSize: 14.0),
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.black26, fontSize: 14.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
              ),
            )),
            SizedBox(width: 10),
            ElevatedButton(onPressed: sendFunction, child: Text('Send!')),
          ]),
        ],
      ),
    );
  }

  Widget setRoomExtraInfoWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(children: [
            Text('📢 Room Extra Info', style: TextStyle(fontSize: 15),),
          ],),
          SizedBox(height: 5),
          Row(children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 5,
                    child: TextField(
                      controller: _roomExtraInfoKeyController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(10.0),
                        isDense: true,
                        labelText: 'Key',
                        labelStyle: TextStyle(color: Colors.black54, fontSize: 14.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _roomExtraInfoValueController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(10.0),
                        isDense: true,
                        labelText: 'Value',
                        labelStyle: TextStyle(color: Colors.black54, fontSize: 14.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0e88eb)))
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(onPressed: setRoomExtraInfo, child: Text('Set!')),
          ]),
        ],
      ),
    );
  }

  Widget roomInfoWidget() {
    return Row(children: [
      Text("RoomID: $_roomID | UserID: ${ZegoConfig.instance.userID}", style: TextStyle(fontSize: 8),),
      Spacer(),
      Text(roomStateDesc(), style: TextStyle(fontSize: 10),),
    ], crossAxisAlignment: CrossAxisAlignment.center);
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


