import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:dex_for_doctor/mainScreen.dart';
import 'package:dex_for_doctor/main.dart';

import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:phonecallstate/phonecallstate.dart';

//enum PhonecallState { incoming, dialing, connected, disconnected, none }

class RecorderWidget extends StatefulWidget {
  const RecorderWidget({Key key, this.email});

  final String email;

  @override
  _RecorderWidgetState createState() => _RecorderWidgetState();
}

class _RecorderWidgetState extends State<RecorderWidget> {
  int pauseButtonState = 0;

  @override
  initState() {
    super.initState();

//    initPhCallState();
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
                              //for paused state
                              //only for sdk < 24 to support that resume pause thing
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
//  _audioRecorderFunction(int recordState,int saveAndTranscribe)
  //saveAndTranscribe=0; just save
  //saveAndTranscribe=1; save and transcribe
  List<String> uploadAudioURLArray = [];
  _audioRecorderFunction(int recordState, int saveAndTranscribe) async {
    String path;
    //THIS IS RECORD
    //AND RESUME
    if (recordState == 1) {
      try {
        if (await AudioRecorder.hasPermissions) {
          //CREATE DIRECTORY-Path
          Directory appDocDirectory = await getApplicationDocumentsDirectory();

          String fileNameT = new DateTime.now().millisecondsSinceEpoch.toString();

          path = appDocDirectory.path + '/DeX' +
              '/' +
              'DeX-' +
              fileNameT;

          storageRedundancyList.add(fileNameT);

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
    //THIS IS PAUSE | Stopping recording
    else if (recordState == 2) {

      var recording = await AudioRecorder.stop();
      File file = new File(recording.path);
      print("Stop recording: ${recording.path} | File length: ${await file.length()}");

      //UPLOAD FAILS IF FILES SIZE > 40MB
      if (await file.length() > 40000000) {

        snackbarOverSizeWarn(context);

      } else {

        await fileUploadStorage(file, recording);

      }
    }
    //THIS IS STOP | REAL TIME DATABASE & Fire store IS UPDATED IS HERE
    else {
      var recording = await AudioRecorder.stop();
      File file = new File(recording.path);
      print("Stop recording: ${recording.path} | File length: ${await file.length()}");

      //UPLOAD FAILS IF FILES SIZE > 40MB
      if (await file.length() > 40000000) {

        snackbarOverSizeWarn(context);

      } else {

        await listPEntry(saveAndTranscribe,file, recording);

        await bigListRequestEntry(saveAndTranscribe);

      }
    }
  }

//CREATE A BACKEND REQUEST IN BIG LIST
//GET KEY for BIG LIST
//PUSH BASICS
//ADD AUDIOS TO THE LIST
//USING BIG LIST WITH FIRE STORE TO KEEP A BACKUP
Future bigListRequestEntry(saveAndTranscribe) async{
  print(">>>UPLOADING TO TRANSCRIPTION BIG LIST");
  //GET KEY for BIG LIST
  String keyForBigList = FirebaseDatabase.instance
      .reference()
      .child("DeXAutoCollect")
      .child("backend")
      .child("oneBigListOfEMRRequests")
      .push()
      .key;
  //PUSH BASICS
  await FirebaseDatabase.instance
      .reference()
      .child("DeXAutoCollect")
      .child("backend")
      .child("backupList")
      .child(keyForBigList)
      .set({
    "em": widget.email.replaceAll(".", " "),
    "ti": new DateFormat.yMd().add_jm().format(new DateTime.now()),
    "ty":saveAndTranscribe
  });
  //ADD AUDIOS TO THE LIST USING LOOP
  for (int k = 0; k < uploadAudioURLArray.length; k++) {
    print("Uploading To BIG: $k ${uploadAudioURLArray[k]}");
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("backend")
        .child("backupList")
        .child(keyForBigList)
        .update({
      "audioURL-" + k.toString(): uploadAudioURLArray[k]
    });
  }
}

//UPLOAD TO FIRE BASE STORAGE
Future fileUploadStorage(file,recording)async{

  String usid;
  await auth.currentUser().then((user){
    usid=user.uid;
    print("UPLOADING TO LIST P | uid>> ${user.uid}");
  });

  //UPLOAD FILE
  print(">>>UPLOADING FILE USING UPLOADTASK");
  StorageReference ref = FirebaseStorage.instance
      .ref()
      .child("Audio")
      .child(usid)
      .child(recording.path
      .toString()
      .substring(recording.path.toString().length - 21,recording.path.toString().length));

  StorageUploadTask uploadTask = ref.putFile(file);

  await uploadTask.future.catchError((error){
    //
    print(">>Error IN UPLOAD"+error);
  });


  //GET URL
  Uri fileUrl = (await uploadTask.future).downloadUrl;

  print("File Uploaded == > ${recording.path.toString()}");


  //Delete File
  await uploadTask.future.whenComplete((){
    //delete file
    file.deleteSync(recursive: true);
    print(">>File is DELETED");
  });


  //ARRAY HOLDS URL TO STORAGE
  uploadAudioURLArray.add(fileUrl.toString());
  print(">>>FILE UPLOADED| Url array holdings: $uploadAudioURLArray");
}

//SNACKBAR WARNING MORE THAN 40 MB
snackbarOverSizeWarn(context){
  Scaffold.of(context).showSnackBar(
    new SnackBar(
      content: new Text(
        "Upload Failed! File size greater than 40MB; Please contact support",
        style: new TextStyle(color: Colors.yellow, fontSize: 20.0),
      ),
      duration: new Duration(seconds: 50),
    ),
  );
}

//FIRE STORE listP
Future listPEntry(saveAndTranscribe,file, recording)async{

    String usid;
    await auth.currentUser().then((user){
      usid=user.uid;
      print("UPLOADING TO LIST P | uid>> ${user.uid}");
    });
    //UPLOAD BASICS
    String docuId;
    await Firestore.instance.collection('listP').add({
//      "em": widget.email.replaceAll(".", " "),
      "ti": new DateTime.now().millisecondsSinceEpoch,
      "usid":usid,
      "ty":saveAndTranscribe,
      "st":0,
      "r-d":storageRedundancyList
    }).then((val){
      print(">>key ${val.documentID}");
      docuId = val.documentID;
    });

    //CLEAR THE LIST
    storageRedundancyList.clear();
    print("Storage Redun: "+storageRedundancyList.toString());
    //redundancy write
    //find a better logic
//    for (int k = 0; k < storageRedundancyList.length; k++) {
//      print("Uploading storageRedundancyList: $k ${storageRedundancyList[k]}");
//      await Firestore.instance.collection('listP').document(docuId).updateData({
//        "a-" + k.toString(): storageRedundancyList[k]
//      });
//    }

    await fileUploadStorage(file, recording);

    //UPLOAD AUDIO URLS
    //NOT UPLOADING AUDIO URLS AS AUDIO CAN BE
//    for (int k = 0; k < uploadAudioURLArray.length; k++) {
//      print("Uploading To listP: $k ${uploadAudioURLArray[k]}");
//      await Firestore.instance.collection('listP').document(docuId).updateData({
//        "a-" + k.toString(): uploadAudioURLArray[k]
//      });
//    }

    print(">>ALL DONE WITH");
}


  //PHONE PERMISSIONS AND PAUSE DURING PHONE
/*  Phonecallstate phonecallstate;
  PhonecallState phonecallstatus;
  initPhCallState() async {
    print("Phonecallstate init");

    phonecallstate = new Phonecallstate();
    phonecallstatus = PhonecallState.none;

     phonecallstate.setIncomingHandler(() {
      setState(() {
        phonecallstatus = PhonecallState.incoming;
      });
    });

    phonecallstate.setDialingHandler(() {
      setState(() {
        phonecallstatus = PhonecallState.dialing;

      });
    });

    phonecallstate.setConnectedHandler(() {
      setState(() {
        phonecallstatus = PhonecallState.connected;
        _audioRecorderFunction(2, 0); //pause
        stopWatch.stop();
      });
    });

    phonecallstate.setDisconnectedHandler(() {
      setState(() {
        phonecallstatus = PhonecallState.disconnected;
        _audioRecorderFunction(1, 0); //resume
        stopWatch.start();
      });
    });

    phonecallstate.setErrorHandler((msg) {});
  }*/
}
