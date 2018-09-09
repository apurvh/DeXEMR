import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:dex_for_doctor/mainScreen.dart';
import 'package:dex_for_doctor/main.dart';

//import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_state_i/phone_state_i.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/services.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

StreamSubscription streamAu;

int pauseButtonState;

class RecorderWidget extends StatefulWidget {
  const RecorderWidget({Key key, this.email, this.analytics, this.observer});

  final String email;
  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;

  @override
  _RecorderWidgetState createState() => _RecorderWidgetState();
}

class _RecorderWidgetState extends State<RecorderWidget> {
//  int pauseButtonState;
  AudioCache player = new AudioCache(prefix: 'sounds/');

  @override
  initState() {
    super.initState();
    initPhCallState();
    player.load('ting2.mp3');
  }

  @override
  Widget build(BuildContext context) {
    if (false) {
      return new Container();
    } else {
      print("Timer Redrawn==================");

      return new Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        padding: const EdgeInsets.fromLTRB(12.0, 25.0, 12.0, 7.0),
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
        child: Column(
          children: <Widget>[
            new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                new ScopedModelDescendant<CounterModel>(
                  builder: (context, child, model) => pauseButton(model),
                ),
                new ScopedModelDescendant<CounterModel>(
                    builder: (context, child, model) => timer(
                        model.elapsedTimeMin, model.elapsedTimeSec, model)),
                new Column(
                  children: <Widget>[
                    new ScopedModelDescendant<CounterModel>(
                      builder: (context, child, model) => new RawMaterialButton(
                            onPressed: () {
                              print(">>>>>> jUST SAVE");
                              _justSaveEventLog(stopWatch.elapsedMicroseconds);

                              //for paused state
                              if (pauseButtonState == 1) {
                                Scaffold.of(context).showSnackBar(new SnackBar(
                                      content: new Text(
                                        "FIrst Resume -> then Save",
                                      ),
                                      duration: new Duration(seconds: 4),
                                    ));
                              } else {
                                model.decrement();
                                print("====>>>>  ${model.counter}");
                                _audioRecorderFunction(model.counter, 0);

                                Scaffold.of(context).showSnackBar(new SnackBar(
                                      content: new Text(
                                        "Uploading Audio File ...",
                                      ),
                                      duration: new Duration(seconds: 8),
                                    ));
                              }
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
            Padding(
              padding: const EdgeInsets.only(right: 28.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  new Container(
                    decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        boxShadow: [
                          new BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2.0,
                              spreadRadius: 1.0),
                        ]),
                    padding: const EdgeInsets.all(5.0),
                    child: new ScopedModelDescendant<CounterModel>(
                      builder: (context, child, model) => new RawMaterialButton(
                            onPressed: () {
                              print(">>>>>> SAVE AND SEND TO TRANSCRIPTION");
                              _saveAndTransEventLog(stopWatch.elapsedMicroseconds);
                              //for paused state
                              if (pauseButtonState == 1) {
                                Scaffold.of(context).showSnackBar(new SnackBar(
                                      content: new Text(
                                        "FIrst Resume -> then Save",
                                      ),
                                      duration: new Duration(seconds: 4),
                                    ));
                              } else {
                                model.decrement();
                                print("====>>>>  ${model.counter}");
                                _audioRecorderFunction(model.counter, 1);

                                Scaffold.of(context).showSnackBar(new SnackBar(
                                      content: new Text(
                                        "Uploading Audio File ...& Sending to Transcription",
                                      ),
                                      duration: new Duration(seconds: 8),
                                    ));
                              }
                            },
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              children: <Widget>[
                                new Icon(
                                  Icons.done_all,
                                  size: 60.0,
                                  color: Colors.teal[500],
                                ),
                                new Text(
                                  "Save & \nTranscribe",
                                  style: new TextStyle(
                                    color: Colors.teal[500],
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            shape: new CircleBorder(),
                            elevation: 1.0,
                            fillColor: Colors.grey[100],
                          ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );
    }
  }

  Widget timer(String mins, String secs, model) {
//    print("timer drwn!!!!");

    //KEEPING VALUE OF STRING LESS THAN 60
    int intSecs =
        int.parse(secs).toInt() - (int.parse(secs).toInt() ~/ 60) * 60;
    String stringSecs = intSecs.toString().padLeft(2, '0');
    //ENDS

    refreshTimer(int.parse(mins), model);

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
              mins + ":" + stringSecs,
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

  Future refreshTimer(int mins, model) async {
//    print(">>>value of timer $mins");
//    print(">>>>>>ph CALL STATE: " + phonecallstatuslog.toString());
    sleep(const Duration(milliseconds: 1000));
    setState(() {});
  }

  ///pauseButtonState=0 // pause

  Widget pauseButton(model) {
    if (pauseButtonState == 0) {
      return new Column(
        children: <Widget>[
          new RawMaterialButton(
            onPressed: () {
              pauseButtonState = 1;
              print("PAUSE PRESSED");
              _audioRecorderFunction(2, 0);
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
              _audioRecorderFunction(1, 0);
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
  //1 = Start RECORDING
  //2 = PAUSE RECORDING
  //3 = RESUME RECORDING
  //saveAndTranscribe=0; just save
  //saveAndTranscribe=1; save and transcribe

  _audioRecorderFunction(int recordState, int saveAndTranscribe) async {
    String path;
    //THIS IS RECORD
    //AND RESUME
    if (recordState == 1) {
      try {
        if (await AudioRecorder.hasPermissions) {
          //CREATE DIRECTORY-Path
          Directory appDocDirectory = await getApplicationDocumentsDirectory();

          String fileNameT =
              new DateTime.now().millisecondsSinceEpoch.toString();

          path = appDocDirectory.path + '/DeX' + '/' + 'DeX-' + fileNameT;

          storageRedundancyList.add(fileNameT);
          bigListStorageBackup.add(fileNameT);

          print("Start resumed recording: $path");

          await AudioRecorder.start(
              path: path, audioOutputFormat: AudioOutputFormat.AAC);

//          bool isRecording = await AudioRecorder.isRecording;

        } else {
          Scaffold.of(context).showSnackBar(
              new SnackBar(content: new Text("You must accept permissions")));
        }
      } catch (e) {
        print(e);
      }
    }
    ///THIS IS PAUSE | Stopping recording
    else if (recordState == 2) {
      var recording = await AudioRecorder.stop();
      File file = new File(recording.path);
      print("Stop recording: ${recording.path} | File length: ${await file
          .length()}");

      ///UPLOAD FAILS IF FILES SIZE > 40MB
      if (await file.length() > 40000000) {
        snackbarOverSizeWarn(context);
        file.deleteSync(recursive: true);
      } else {
        String docuId = 'NoChnageInSt';
        await fileUploadStorage(file, recording, docuId);
      }

//      globalRecorderState=0;

    }
    ///THIS IS STOP | REAL TIME DATABASE & Fire store IS UPDATED IS HERE
    else {
      //Done Sound
      player.play('ting2.mp3');

      var recording = await AudioRecorder.stop();
      File file = new File(recording.path);
      print("Stop recording: ${recording.path} | File length: ${await file
          .length()}");

      //UPLOAD FAILS IF FILES SIZE > 40MB
      if (await file.length() > 40000000) {
        snackbarOverSizeWarn(context);
        file.deleteSync(recursive: true);
      } else {
        await listPEntry(saveAndTranscribe, file, recording);

        await bigListRequestEntry(saveAndTranscribe);
      }

      globalRecorderState = 0;

    }
  }

  ///USING BIG LIST WITH FIRE STORE TO KEEP A BACKUP
  Future bigListRequestEntry(saveAndTranscribe) async {
    print(">>>UPLOADING TO TRANSCRIPTION BIG LIST");
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("backend")
        .child("backupLi6Sept18")
        .push()
        .set({
      "em": widget.email.replaceAll(".", " "),
      "ty": saveAndTranscribe,
      'ad': bigListStorageBackup
    }).then((onV) {
      bigListStorageBackup.clear();
    });
  }

  ///UPLOAD TO FIRE BASE STORAGE
  Future fileUploadStorage(file, recording, docuId) async {
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("UPLOADING TO LIST P | uid>> ${user.uid}");
    });
    print(">>>UPLOADING FILE USING UPLOADTASK");
    StorageReference ref = FirebaseStorage.instance
        .ref()
        .child("Audio")
        .child(usid)
        .child(recording.path.toString().substring(
            recording.path.toString().length - 21,
            recording.path.toString().length));

    StorageUploadTask uploadTask =
        ref.putFile(file, StorageMetadata(contentType: 'audio/m4a'));

    await uploadTask.future.catchError((error) {
      print(">>Error IN UPLOAD" + error);
    });

    print("File Uploaded == > ${recording.path.toString()}");

    ///Delete File
    ///Set st=0
    await uploadTask.future.whenComplete(() {
      //delete file
      file.deleteSync(recursive: true);
      print(
          ">>>FILE UPLOADED| LOCAL FILE DELETED |Url array holdings: $bigListStorageBackup");

      if (docuId != 'NoChnageInSt') {
        Firestore.instance.collection('listP').document(docuId).updateData({
          'st': 0,
        }).then((doc) {
          print('>>st value changed to st=0 ');
        });
      }
    });
  }

  ///SNACKBAR WARNING MORE THAN 40 MB
  snackbarOverSizeWarn(context) {
    Scaffold.of(context).showSnackBar(
          new SnackBar(
            content: new Text(
              "Upload Failed! File size greater than 40MB; File Deleted! Please contact support",
              style: new TextStyle(color: Colors.yellow, fontSize: 20.0),
            ),
            duration: new Duration(seconds: 50),
          ),
        );
  }

  ///FIRE STORE listP
  Future listPEntry(saveAndTranscribe, file, recording) async {
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("UPLOADING TO LIST P | uid>> ${user.uid}");
    });

    String docuId;
    await Firestore.instance.collection('listP').add({
//      "em": widget.email.replaceAll(".", " "),
      "ti": new DateTime.now().millisecondsSinceEpoch,
      "usid": usid,
      "ty": saveAndTranscribe,
      "st": 1,
      "r-d": storageRedundancyList
    }).then((val) {
      print(">>key ${val.documentID}");
      docuId = val.documentID;
      //CLEAR THE LIST
      storageRedundancyList.clear();
      print("Storage Redun: " + storageRedundancyList.toString());
    });

    ///Update the Main counter
    String updateTotalTranscriptionKey;
    int updateTotalRecs;
    int updateTotalTrans;
    int updateTotalTime;

    await Firestore.instance
        .collection('docsP')
        .where('usid', isEqualTo: usid)
        .getDocuments()
        .then((d) {
      updateTotalRecs = d.documents[0]['nre'];
      updateTotalTrans = d.documents[0]['nrt'];
      updateTotalTime = d.documents[0]['nrm'];
      updateTotalTranscriptionKey = d.documents[0].documentID;
    });
    await Firestore.instance
        .collection('docsP')
        .document(updateTotalTranscriptionKey)
        .updateData({
      'nre': updateTotalRecs + 1,
      'nrt': updateTotalTrans + saveAndTranscribe,
      'nrm':updateTotalTime + stopWatch.elapsed.inMinutes+1,
    });

    stopWatch.reset();
    await fileUploadStorage(file, recording, docuId);

    print(">>ALL DONE WITH");
  }

  ///PHONE PERMISSIONS AND STOP DURING PHONE
  initPhCallState() async {
    //Refresh widgets
    SystemChannels.lifecycle.setMessageHandler((msg) {
      debugPrint('SystemChannels> $msg');
      if (msg == AppLifecycleState.resumed.toString()) setState(() {});
      print('DEBUG: pauseButtonState=$pauseButtonState | ');
    });

    streamAu = phoneStateCallEvent.listen((PhoneStateCallEvent event) {
      print('Call is Incoming/Connected::: ' +
          event.stateC +
          ' $globalRecorderState ');
      //event.stateC has values "true" or "false"
      if (event.stateC == 'true') {
        //stop
        AudioRecorder.isRecording.then((vol) {
          if (vol == true) {

            if (globalRecorderState == 0) {
              print('>>Recorder is Pause--Stopped because of call');
              pauseButtonState = 1;
              _audioRecorderFunction(2, 0);
              stopWatch.stop();
            }

            //permit start audio recording
            globalRecorderState = 1;
          }
        });
      } else if (event.stateC == 'false') {
        //resume
        if (globalRecorderState == 1) {

          if (Theme.of(context).platform == TargetPlatform.android) {
            print('>>Recorder is Resumed because of call | ANDROID');
            _audioRecorderFunction(1, 0);
            stopWatch.start();
            pauseButtonState = 0;
          }

          //cancel permission
          globalRecorderState = 0;
        }
      }
    });
  }

  ///Login Tracking via firebase analytics
  Future<Null> _justSaveEventLog(time) async {
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("UPLOADING TO LIST P | uid>> ${user.uid}");
    });
    if(usid != 'H0ZF7TpTjZNLzFPRBDnzX48surU2'){
      await widget.analytics.logEvent(
        name: 'justSave',
        parameters: <String, dynamic>{
          'time': time,
        },
      );
      print('logEvent-_justSaveEventLog succeeded | ${new DateTime.now()}');
    }
  }

  ///Login Tracking via firebase analytics
  Future<Null> _saveAndTransEventLog(time) async {
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("UPLOADING TO LIST P | uid>> ${user.uid}");
    });
    if(usid != 'H0ZF7TpTjZNLzFPRBDnzX48surU2'){
      await widget.analytics.logEvent(
        name: 'saveAndTrans',
        parameters: <String, dynamic>{
          'time': time,
        },
      );
      print('logEvent-_saveAndTransEventLog succeeded | ${new DateTime.now()}');
    }
  }
}
