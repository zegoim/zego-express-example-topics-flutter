import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class ZegoUtils {

  static showAlert(BuildContext context, String message) {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Tips'),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      );
    });
  }

  static showImage(BuildContext context, MemoryImage? imageData, {String? path}) {
    showDialog(context: context, builder: (BuildContext context) {
      if (imageData == null ) {
        print('[ZegoUtils][showImage] image data is null!');
        return Container();
      }

      return AlertDialog(
        content: Container(
          width: MediaQuery.of(context).size.width / 2, 
          height: MediaQuery.of(context).size.width *3/4,
          child: Column(
            children: [
              Image(image: imageData, width: MediaQuery.of(context).size.width / 2, height: MediaQuery.of(context).size.width / 2),
              Text('save path: $path',style: TextStyle(fontSize: 9),)
            ],
          ) 
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('cancle'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            child: Text('save'),
            onPressed: () {
              if (path != null) {
                var img = File(path);
                img.writeAsBytes(imageData.bytes);
              }
              Navigator.of(context).pop();
            },
          )
        ],
      );
    });
  }

  static shareLog() async {

    var shareLogFuntion = (String? sdkPath) async {
      if (sdkPath != null) {
        var logZipPath = sdkPath + '/log.zip';
        var logZipFile = File(logZipPath);
        if (logZipFile.existsSync()) {
          await logZipFile.delete();
          print('delete log zip path: $logZipPath');
        }

        var encoder = ZipFileEncoder();
        encoder.create(logZipPath);
        for (var i = 1; i <= 3; i++) {
          var logFile = File('$sdkPath/zegoavlog$i.txt');
          if (logFile.existsSync()) {
            print('$sdkPath/zegoavlog$i.txt exists');
            encoder.addFile(logFile);
          }
        }
        encoder.close();

        Share.shareFiles([logZipPath], subject: '日志', text: '分析');
      }
    };

    if (Platform.isAndroid)
    {
      getExternalStorageDirectories().then((dir) async {
        var sdkPath = dir?[0].path;
        print('sdk log path: $sdkPath');
        await shareLogFuntion(sdkPath);
      });
    } else {
      getTemporaryDirectory().then((dir) async {
        print('sdk log path: ${dir.path}/ZegoLogs');
        await shareLogFuntion(dir.path + '/ZegoLogs');
      });
    }
  }
}