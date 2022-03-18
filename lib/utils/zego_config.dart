import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math' show Random;

import 'package:zego_express_engine/zego_express_engine.dart' show ZegoScenario;

class ZegoConfig {

  static final ZegoConfig instance = ZegoConfig._internal();
  ZegoConfig._internal();

  // ----- Persistence params -----
  // Developers can get appID from admin console.
  // https://console.zego.im/dashboard
  // for example:
  //     private long _appID = 123456789L;
  int appID = 0;

  ZegoScenario scenario = ZegoScenario.General;

  bool enablePlatformView = false;

  // Developers should customize a user ID.
  // for example:
  //     private String _userID = "zego_benjamin";
  String userID = "";
  
  String userName = "";

  // Developers can get token from admin console.
  // https://console.zego.im/dashboard
  // Note: The user ID used to generate the token needs to be the same as the userID filled in above!
  // for example:
  //     private String _token = "04AAAAAxxxxxxxxxxxxxx";
  String token = "";

  String roomID = "";
  String streamID = "";

  // ----- Short-term params -----

  bool isPreviewMirror = true;
  bool isPublishMirror = false;

  bool enableHardwareEncoder = false;

}