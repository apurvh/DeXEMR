import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:dex_for_doctor/mainScreen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RecorderWidget extends StatefulWidget {
  const RecorderWidget({Key key, this.email});

  final String email;

  @override
  _RecorderWidgetState createState() => _RecorderWidgetState();
}

class _RecorderWidgetState extends State<RecorderWidget> {
  int pauseButtonState = 0;

  @override
  Widget build(BuildContext context) {
    if (false) {
      return new Container();
    } else {
      print("whole Widget drwn!!!!");

      return new Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        padding: const EdgeInsets.fromLTRB(12.0, 25.0, 12.0, 25.0),
        decoration: new BoxDecoration(
          boxShadow: [
            new BoxShadow(
              spreadRadius: 1.0,
              blurRadius: 2.0,
              color: Colors.grey,
            )
          ],
          color: Colors.blueGrey[50],
        ),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new ScopedModelDescendant<CounterModel>(
              builder: (context, child, model) => pauseButton(model),
            ),
            new ScopedModelDescendant<CounterModel>(
                builder: (context, child, model) =>
                    timer(model.elapsedTimeMin, model.elapsedTimeSec)),
            new Column(
              children: <Widget>[
                new ScopedModelDescendant<CounterModel>(
                  builder: (context, child, model) => new RawMaterialButton(
                        onPressed: () {
                          model.decrement();
                          print("====>>>>  ${model.counter}");
                          redButtonStateChannelFunction(model.counter);
                          Scaffold.of(context).showSnackBar(new SnackBar(
                                content: new Text(
                                  "Uploading Audio File ...",
                                ),
                                duration: new Duration(seconds: 4),
                              ));
                        },
                        child: new Icon(
                          Icons.done,
                          size: 40.0,
                          color: Colors.teal[600],
                        ),
                        shape: new CircleBorder(),
                        elevation: 2.0,
                        fillColor: Colors.white,
                        padding: const EdgeInsets.all(15.0),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: new Text(
                    "Save",
                    style: new TextStyle(
                      color: Colors.teal[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget timer(String mins, String secs) {
    print("timer drwn!!!!");
    refreshTimer();
    return new Container(
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.red[300],
          width: 10.0,
        ),
        boxShadow: [
          new BoxShadow(
            blurRadius: 1.0,
            spreadRadius: 0.0,
            color: Colors.red[800],
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Text(
              mins + ":" + secs,
              style: new TextStyle(
                fontSize: 25.0,
                color: Colors.grey[900],
//                      fontWeight: FontWeight.bold,
              ),
            ),
            new Text(
              "Timer",
              style: new TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future refreshTimer() async {
    sleep(const Duration(milliseconds: 100));
    setState(() {});
  }

  Widget pauseButton(model) {
    if (pauseButtonState == 0) {
      return new Column(
        children: <Widget>[
          new RawMaterialButton(
            onPressed: () {
              pauseButtonState = 1;
              print("PAUSE PRESSED");
              redButtonStateChannelFunction(2);
              model.stopWatchPause();
              setState(() {});
            },
            child: new Icon(
              Icons.pause,
              size: 40.0,
              color: Colors.blueGrey[800],
            ),
            shape: new CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(15.0),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: new Text(
              "Pause",
              style: new TextStyle(
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      return new Column(
        children: <Widget>[
          new RawMaterialButton(
            onPressed: () {
              pauseButtonState = 0;
              print("RESUME PRESSED");
              redButtonStateChannelFunction(3);
              model.stopWatchResume();
              setState(() {});
            },
            child: new Icon(
              Icons.play_arrow,
              size: 40.0,
              color: Colors.blueGrey[800],
            ),
            shape: new CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(15.0),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: new Text(
              "Resume",
              style: new TextStyle(
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
  }

  //0 = STOP RECORDING
  //1 = PLAY RECORDING
  //2 = PAUSE RECORDING
  //3 = RESUME RECORDING
  //PLATFORM
  static const platform = const MethodChannel('dex.channels/dfRedButtonState');

  //USING PLATFORM CHANNEL TO CAPTURE AUDIO AND SEND TO FIRE BASE DB
  Future redButtonStateChannelFunction(int redButtonState) async {
    String result = await platform.invokeMethod('stateReply', {
      'redButtonState': redButtonState,
      'time': new DateTime.now().millisecondsSinceEpoch.toString()
    });
    print("RESULT IS: " + result);

//    stillUploadingLastOne = 1;

    //GET KEY
    String uploadAudioFileKey = FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(widget.email.replaceAll(".", " "))
        .push()
        .key;

//    print(uploadAudioFileKey);
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(widget.email.replaceAll(".", " "))
        .child(uploadAudioFileKey)
        .update({
      "name": result.substring(result.length - 21),
      "conversionStatus": 0,
//      "followUp": followUpStatus,
      "dateStamp": new DateFormat.yMd().format(new DateTime.now())
    });

    //UPLOAD FILE AND PUSH FILE
    if (result != "Recording On ") {
      //UPLOAD FILE
      File file = new File(result);
      StorageReference ref = FirebaseStorage.instance
          .ref()
          .child("Audio")
          .child(widget.email.replaceAll(".", " "))
          .child(result.substring(result.length - 21));
      StorageUploadTask uploadTask = ref.put(file);

      //GET URL
      Uri fileUrl = (await uploadTask.future).downloadUrl;
      print("File Uploaded == > $result");

      //PUSH TO AUDIO
      await FirebaseDatabase.instance
          .reference()
          .child("DeXAutoCollect")
          .child("list")
          .child(widget.email.replaceAll(".", " "))
          .child(uploadAudioFileKey)
          .update({
        "url": fileUrl.toString(),
      });
    }
//    stillUploadingLastOne = 0;
  }
}
