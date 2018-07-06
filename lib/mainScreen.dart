import 'package:flutter/material.dart';
import 'package:dex_for_doctor/recorderWidget.dart';
import 'package:dex_for_doctor/emrListWidget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  const MainScreen({Key key, this.email});

  final String email;

  @override
  _MainScreenState createState() => new _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    String _emailID = widget.email;

    return new ScopedModel<CounterModel>(
      model: new CounterModel(),
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text("DeX EMR"),
          elevation: 3.0,
          backgroundColor: Colors.teal[800],
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.search),
              onPressed: () {},
            )
          ],
        ),
        body: new Column(
          children: <Widget>[
            new ScopedModelDescendant<CounterModel>(
              builder: (context, child, model) =>
                  renderRecordWidget(model.counter),
            ),
            Expanded(
              child: new EMRListWidget(email: _emailID),
            ),
          ],
        ),
        floatingActionButton: new ScopedModelDescendant<CounterModel>(
          builder: (context, child, model) => renderFloatingActionButton(model),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget renderRecordWidget(int recorderWidgetState) {
    if (recorderWidgetState == 0) {
      return Container();
    } else {
      return new RecorderWidget(
        email: widget.email,
      );
    }
  }

  Widget renderFloatingActionButton(model) {
    if (model.counter == 1) {
      return Container();
    } else {
      return new Container(
        decoration: new BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
            boxShadow: [
              new BoxShadow(
                  color: Colors.grey, blurRadius: 2.0, spreadRadius: 1.0),
            ]),
        padding: const EdgeInsets.all(5.0),
        child: new RawMaterialButton(
          onPressed: () {
            model.increment();
            print("====>>>>  ${model.counter}");
            redButtonStateChannelFunction(model.counter);
          },
          padding: const EdgeInsets.all(30.0),
          child: new Text(
            "+New",
            style: new TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: new CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.teal[500],
        ),
      );
    }
  }

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

    //UPLOAD FILE AND PUSH FILE
    if (result != "Recording On ") {
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

//THIS MODEL STORES AND PASSES DATA SUCH AS TIME AND STATES OF RECORDER WIDGET AND STOPWATCH
class CounterModel extends Model {
  int _counter = 0;
  int get counter => _counter;

  //GETTERS FOR ELAPSED MINUTES AND SECONDS
  var stopWatch = new Stopwatch();
  String get elapsedTimeSec =>
      stopWatch.elapsed.inSeconds.toString().padLeft(2, '0');
  String get elapsedTimeMin =>
      stopWatch.elapsed.inMinutes.toString().padLeft(2, '0');

  void stopWatchResume() {
    stopWatch.start();
    notifyListeners();
  }

  void stopWatchPause() {
    stopWatch.stop();
    notifyListeners();
  }

  void increment() {
    // First, increment the counter
    _counter = 1;
    stopWatch.start();

    // Then notify all the listeners.
    notifyListeners();
  }

  void decrement() {
    // First, increment the counter
    _counter = 0;
    stopWatch.stop();
    stopWatch.reset();

    // Then notify all the listeners.
    notifyListeners();
  }
}
