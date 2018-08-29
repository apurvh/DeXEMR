import 'package:flutter/material.dart';
import 'package:dex_for_doctor/recorderWidget.dart';
import 'package:dex_for_doctor/emrListWidget.dart';
import 'package:dex_for_doctor/insights.dart';


import 'package:google_sign_in/google_sign_in.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'dart:io';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:simple_permissions/simple_permissions.dart';
import 'package:scheduled_notifications/scheduled_notifications.dart';
import 'package:dex_for_doctor/searchF.dart';

int globalRecorderState=0;

List<String> storageRedundancyList = [];

var stopWatch = new Stopwatch();

class MainScreen extends StatefulWidget {
  const MainScreen({Key key, this.email});

  final String email;

  @override
  _MainScreenState createState() => new _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BuildContext contextForRecorder;



  @override
  Widget build(BuildContext context) {
    String _emailID = widget.email;

    return new ScopedModel<CounterModel>(
      model: new CounterModel(),
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text("DeX Notes"),
          elevation: 3.0,
          backgroundColor: Colors.teal[800],

          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SearchF(
                            email: _emailID,
                          )),
                );
              },
            ),
            RaisedButton.icon(
              onPressed: () {
                Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
                  return new InsightsData();
                }));
              },
              icon: Icon(Icons.dashboard),
              label: Text('Insights'),
              color: Colors.green[700],
              textColor: Colors.blueGrey[50],
            ),
          ],
        ),
        body: new Builder(builder: (BuildContext context) {
          contextForRecorder = context;
          return new Column(
            children: <Widget>[
              new ScopedModelDescendant<CounterModel>(
                builder: (context, child, model) =>
                    renderRecordWidget(model.counter),
              ),
              Expanded(
                child: new EMRListWidget(email: _emailID),
              ),
            ],
          );
        }),
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
            renderFloatingActionButtonFunction(model);
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

  renderFloatingActionButtonFunction(model) async {
    if (await AudioRecorder.hasPermissions) {
      //await AudioRecorder.hasPermissions instead of true
      model.increment();
      print("====>>>>  ${model.counter} ==>Started Recording...");
      _audioRecorderFunction(model.counter);
    } else {
      print("====>>>>NO AUDIO PERMISSIONS");
      if(Theme.of(context).platform == TargetPlatform.android)
        {
          print('Andriod My Man');
//          await SimplePermissions.requestPermission(Permission.RecordAudio);
//          await SimplePermissions
//              .requestPermission(Permission.WriteExternalStorage);
//          await phStatePermissionFunc();
        }
      if(Theme.of(context).platform == TargetPlatform.iOS)
        print('>>iOS is the Platfrom My Man');

      Directory appDocDirectory = await getApplicationDocumentsDirectory();

      //CREATE A DIRECTORY
      if (!await Directory(appDocDirectory.path + '/DeX').exists()) {
        await new Directory(appDocDirectory.path + '/DeX')
            .create(recursive: true)
            .then((Directory dir) {
          print('NEW DIR CREATED>>> ' + dir.path);
        });
      }
    }
  }

  //PLATFORM CHANNEL TO ASK FOR PHONE STATE PERMISSIONS
  static const platform =
      const MethodChannel('dex.channels/phStatePermissions');
  phStatePermissionFunc() async {
    String result = await platform.invokeMethod('stateReply');
    print("RESULT IS: " + result);
  }

  //0 = STOP RECORDING
  //1 = Start RECORDING
  //2 = PAUSE RECORDING
  //3 = RESUME RECORDING
  _audioRecorderFunction(int recordState) async {
    if (recordState == 1) {
      try {
        if (await AudioRecorder.hasPermissions) {

          //CREATE DIRECTORY-Path
          Directory appDocDirectory = await getApplicationDocumentsDirectory();

          //CREATE A DIRECTORY
          if (!await Directory(appDocDirectory.path + '/DeX').exists()) {
            await new Directory(appDocDirectory.path + '/DeX')
                .create(recursive: true)
                .then((Directory dir) {
              print('NEW DIR CREATED>>> ' + dir.path);
            });
          }

          String fileNameT =
              new DateTime.now().millisecondsSinceEpoch.toString();

          String path =
              appDocDirectory.path + '/DeX' + '/' + 'DeX-' + fileNameT;

          storageRedundancyList.add(fileNameT);

          print("Start recording: $path");
          await AudioRecorder.start(
              path: path, audioOutputFormat: AudioOutputFormat.AAC);

//          bool isRecording = await AudioRecorder.isRecording;
        } else {
          Scaffold.of(contextForRecorder).showSnackBar(
              new SnackBar(content: new Text("You must accept permissions")));
        }
      } catch (e) {
        print(e);
      }
    } else {
      var recording = await AudioRecorder.stop();
      print("Stop recording: ${recording.path}");
      File file = new File(recording.path);
      print("  File length: ${await file.length()}");
    }
  }

  Future<Null> ensureLoggedIn() async {
    print("RUNNING ESURE LOOGED IN");
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null) {
      user = await googleSignIn.signInSilently();
    }
    if (user == null) {
      await googleSignIn.signIn();
    }
    if (await auth.currentUser() == null) {
      GoogleSignInAuthentication credentials =
          await googleSignIn.currentUser.authentication;
      await auth.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      );
//      await localStorage.setInt("loginInState", 1);
//      print("Wrote to shared pref local storage: login State: => 1");
    }
    print("ENSURE LOGGED IN SUCCESS: ");
    setState(() {});
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
    _scheduleNotification(1);
    _counter = 1;
    stopWatch.start();

    // Then notify all the listeners.
    notifyListeners();
  }

  void decrement() {
    _scheduleNotification(0);
    _counter = 0;
    stopWatch.stop();
    stopWatch.reset();

    // Then notify all the listeners.
    notifyListeners();
  }
}

//THIS SHOWS A WARNING NOTIFICATION IF AUDIO INCREASES BEYOND 40 MINS
//UPLOADS GREATER THAN 40 MB ARE AUTOMATICALLY BLOCKED
int notificationId;
_scheduleNotification(int status) async {
  if (status == 1) {
    notificationId = await ScheduledNotifications.scheduleNotification(
        new DateTime.now()
            .add(new Duration(minutes: 40))
            .millisecondsSinceEpoch,
        "Alert!",
        "Recording duration has crossed 40 mins.",
        "Recordings more than 60 mins may not get saved.");
  } else {
    await ScheduledNotifications.unscheduleNotification(notificationId);
  }
}
