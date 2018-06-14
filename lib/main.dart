import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:io';
import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();

String _emailID;

//NAME TO BE USED TO LOAD PATIENT EMR
String patientCode;
String patientKey;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DeX - AutoEMR',
      theme: new ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: new MyHomePage(title: 'DeX - AutoEMR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  //STATE TO RECORD/PAUSE
  int _recordPauseSwitch = 0;

  //1 IS SILENT LOGGED IN
  int googleSilentChecker = 0;

  @override
  Widget build(BuildContext context) {
    //CHECK CURRENT USER.. THIS STAYS NULL UNTIL SILENT LOGIN CHECKER ?
    print("Current User: " + googleSignIn.currentUser.toString());

    if (googleSignIn.currentUser == null) {
      return new Scaffold(
        body: new Container(
          child: new Center(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Text(
                  "DeX - AutoEMR",
                  style: new TextStyle(
                      color: Colors.grey[100],
                      fontSize: 38.0,
                      fontWeight: FontWeight.bold),
                ),
                new Text(
                  "Collect Patient Records",
                  style: new TextStyle(
                    color: Colors.grey[200],
                    fontSize: 20.0,
                  ),
                ),
                new Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 58.0),
                  child: new Divider(
                    color: Colors.grey[200],
                  ),
                ),
                buttonThatControlsLoginGoogle(),
              ],
            ),
          ),
          decoration: new BoxDecoration(
              gradient: new RadialGradient(
                  colors: [Colors.teal[200], Colors.teal[400]])),
        ),
      );
    } else {
      BuildContext sssss;
      return new Scaffold(
          appBar: new AppBar(
            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                icon: new Icon(
                  Icons.library_books,
                  color: Colors.grey[100],
                ),
                onPressed: () {
                  Navigator
                      .of(context)
                      .push(new MaterialPageRoute(builder: (context) {
                    return new ListScreen();
                  }));
                },
              ),
            ],
          ),
          body: new Builder(builder: (BuildContext context) {
            sssss = context;
            return new Container(
              color: Colors.grey[50],
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new RawMaterialButton(
                      splashColor: Colors.grey[100],
                      onPressed: () {
                        _recordPauseSwitch = _recordPauseSwitch + 1;
                        redButtonStateChannelFunction();

                        //SHOW SNACK BAR ABOUT UPLOADING
                        if (_recordPauseSwitch.isEven &&
                            _recordPauseSwitch != 0) {
                          Scaffold
                              .of(sssss)
                              .showSnackBar(new SnackBar(
                                content: new Text(
                                  "Uploading Audio File ...",
                                ),
                                duration: new Duration(seconds: 4),
                              ));
                        }

                        setState(() {});
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 18.0),
                      shape: new StadiumBorder(),
                      fillColor: Colors.grey[200],
                      child: redButtonOnPressed()),
                  new Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: redButtonOnPressed2(),
                  )
                ],
              ),
            );
          }));
    }
  }

  @override
  void initState() {
    super.initState();
    print("INIT STATE RUN");
    googleSilentCheckerFunction();
  }

  //LOGIN BUTTON IS INIT
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
    }
    print("ENSURE LOGGED IN SUCCESS: ");
    _emailID = googleSignIn.currentUser.email;
    setState(() {});
  }

  //CHECKS WHTHER USER IS ALREADY GOOGLE SIGNED
  Future googleSilentCheckerFunction() async {
    print("googleSilentCheckerFunction RUN");
    GoogleSignInAccount xUser = googleSignIn.currentUser;
    if (xUser == null) {
      xUser = await googleSignIn.signInSilently();
      if (xUser == null) {
        //failed
        googleSilentChecker = 2;
        setState(() {});
        print("googleSilentCheckerFunction RUN==>2");
      } else {
        //success
        googleSilentChecker = 1;
        setState(() {});
        print("googleSilentCheckerFunction RUN==>1");
        _emailID = googleSignIn.currentUser.email;
      }
    }
  }

  //THIS WIDGET RENDERS GOOGLE SIGN IN OR NOTHING USING STATE
  Widget buttonThatControlsLoginGoogle() {
    if (googleSilentChecker == 2) {
      return new Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: new RaisedButton(
          onPressed: () {
            ensureLoggedIn();
            print("Button PRESSED");
          },
          child: new Image.asset(
            "assets/googleSignIn.png",
            width: 180.0,
            fit: BoxFit.cover,
          ),
          padding: const EdgeInsets.all(0.0),
        ),
      );
    } else {
      return new Container();
    }
  }

  //PLATFORM
  static const platform = const MethodChannel('dex.channels/dfRedButtonState');

  //USING PLATFORM CHANNEL TO CAPTURE AUDIO AND SEND TO FIRE BASE DB
  Future redButtonStateChannelFunction() async {
    String result = await platform.invokeMethod('stateReply', {
      'redButtonState': _recordPauseSwitch,
      'time': new DateTime.now().millisecondsSinceEpoch.toString()
    });
    print("RESULT IS: " + result);

    //UPLOAD FILE AND PUSH FILE
    if (result != "Recording On ") {
      //UPLOAD FILE
      File file = new File(result);
      StorageReference ref = FirebaseStorage.instance
          .ref()
          .child("Audio")
          .child(_emailID.replaceAll(".", " "))
          .child(result.substring(result.length - 21));
      StorageUploadTask uploadTask = ref.put(file);

      //GET URL
      Uri fileUrl = (await uploadTask.future).downloadUrl;
      print("File Uploaded == > $result");

      //PUSH TO AUDIO
      FirebaseDatabase.instance
          .reference()
          .child("DeXAutoCollect")
          .child("list")
          .child(_emailID.replaceAll(".", " "))
          .push()
          .set({
        "url": fileUrl.toString(),
        "name": result.substring(result.length - 21),
        "conversionStatus": 0,
        "followUp": followUpStatus,
        "dateStamp": new DateFormat.yMd().format(new DateTime.now())
      });
      _valueOfSwicth = false;
    }
  }

  //STOP WATCH INIT
  var stopWatch = new Stopwatch();

  //REFRESHING SCREEN to show TIMER VALUE
  Future deadTime() async {
    print("Timer==> " +
        stopWatch.elapsed.inMinutes.toString().padLeft(2, '0') +
        ":" +
        stopWatch.elapsed.inSeconds.toString().padLeft(2, '0'));
    sleep(const Duration(seconds: 1));
    setState(() {});
  }

  //THIS RENDERS START AND SAVE TAP
  Widget redButtonOnPressed() {
    if (_recordPauseSwitch.isEven) {
      stopWatch.stop();
//      print("stopwatch: "+stopWatch.elapsedMilliseconds.toString());
      stopWatch.reset();
      return new Container(
        child: new Column(
          children: <Widget>[
            new Text(
              'Record',
              style: new TextStyle(
                color: Colors.grey[200],
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            new Text(
              '00:00',
              style: new TextStyle(
                color: Colors.grey[200],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        decoration: new BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(68.0),
      );
    } else {
      stopWatch.start();
      return new Container(
        child: new Column(
          children: <Widget>[
            new Text(
              'Tap to Save',
              style: new TextStyle(
                color: Colors.grey[200],
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            redButtonOnPressTimer()
          ],
        ),
        decoration: new BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(68.0),
      );
    }
  }

  //THIS RENDERS TIMER
  Widget redButtonOnPressTimer() {
    //IS THIS THE MOST EFFICIENT WAY?
    deadTime();

    //SO THAT TIMER SECONDS STAYS BELOW 60
    int timeInSecAboveSixty = stopWatch.elapsed.inSeconds;
    if (timeInSecAboveSixty > 59) {
      timeInSecAboveSixty = timeInSecAboveSixty - 60;
    }

    return new Text(
      stopWatch.elapsed.inMinutes.toString().padLeft(2, '0') +
          ":" +
          timeInSecAboveSixty.toString().padLeft(2, '0'),
      style: new TextStyle(
        color: Colors.grey[200],
        fontWeight: FontWeight.normal,
      ),
    );
  }

  //THIS RENDERS FOLLOWUP
  Widget redButtonOnPressed2() {
    if (_recordPauseSwitch.isEven) {
      return new Container();
    } else {
      return new Column(
        children: <Widget>[
          new SwitchListTile(
              title: new Text(
                'Previous/Followup patient',
                style: new TextStyle(color: Colors.teal),
              ),
              activeColor: Colors.teal,
              secondary: new Icon(
                Icons.first_page,
                color: Colors.teal,
              ),
              value: _valueOfSwicth,
              onChanged: (bool value) {
                _onSwitchChanged(value);
              })
        ],
      );
    }
  }

  //INITIAL VALUE OF SWITCH
  bool _valueOfSwicth = false;

  //FOLLOWUP STATUS
  int followUpStatus = 0;

  //SWITCH THAT MANAGES FOLLOW UP PATIENT STATUS
  //0 NEW PATIENT
  //1 FOLLOW UP PATIENT
  void _onSwitchChanged(bool value) {
    setState(() {
      _valueOfSwicth = value;
    });

    //SET FOLLOWUP STATUS
    if (followUpStatus == 1) {
      followUpStatus = 0;
    } else {
      followUpStatus = 1;
    }
    print("FollowUp $followUpStatus");
  }
}

//AFTER CLICKING LIST ICON ON MAIN SCREEN
class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => new _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  BuildContext _scaffoldContext;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Patient Records"),
      ),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return _recordsList();
      }),
    );
  }

  final referenceToRecords = FirebaseDatabase.instance
      .reference()
      .child("DeXAutoCollect")
      .child("list")
      .child(_emailID.replaceAll(".", " "));

  //LIST OF PATIENT RECORDS FROM DB
  Widget _recordsList() {
    return new Column(
      children: <Widget>[
        new Flexible(
          child: new FirebaseAnimatedList(
            query: referenceToRecords,
            itemBuilder:
                (_, DataSnapshot snapshot, Animation<double> animation, int i) {
              return _recordsListTile(snapshot);
            },
            sort: (a, b) => b.key.compareTo(a.key),
            defaultChild: new Center(child: new Text("loading..")),
          ),
        ),
      ],
    );
  }

  Widget _recordsListTile(snapshot) {
    if (snapshot.value["conversionStatus"] == 0) {
      return new Column(
        children: <Widget>[
          new ListTile(
              leading: new Icon(
                Icons.cached,
                size: 15.0,
                color: Colors.grey[400],
              ),
              title: new Text(
                snapshot.value["name"].toString().split(".")[0],
                style: new TextStyle(color: Colors.grey[600]),
              ),
              trailing: new Text(
                snapshot.value["dateStamp"],
                style: new TextStyle(color: Colors.grey[600]),
              )),
          new Divider(),
        ],
      );
    } else {
      return new Column(
        children: <Widget>[
          new ListTile(
            leading: colorOfTick(snapshot),
            title: new Text(
              snapshot.value["newName"],
              style: new TextStyle(
                  color: Colors.grey[900], fontWeight: FontWeight.bold),
            ),
            trailing: new Text(
              snapshot.value["dateStamp"],
              style: new TextStyle(color: Colors.grey[800]),
            ),
            onTap: () {
              //GET KEY AND PASS IT
              patientKey = snapshot.key;
              print("patientKey: " + patientKey);
              referenceToRecords.child(patientKey).update({"seen": 1});

              //SET PATIENT CODE WHICH IS USED TO LAOD PATIENT EMR
              patientCode = snapshot.value["newName"] +
                  "-" +
                  snapshot.value["phone"].toString();
              print("Redirected to EMR and patientCode: " + patientCode);

              //MATERIAL ROUTE TO EMR
              Navigator
                  .of(context)
                  .push(new MaterialPageRoute(builder: (context) {
                return new EMRPage();
              }));
            },
          ),
          new Divider(),
        ],
      );
    }
  }

  //RENDERS COLOR OF TICK IN RECORDS LIST
  Widget colorOfTick(snapshot) {
    if (snapshot.value["seen"] == 1) {
      return new Icon(
        Icons.done_all,
        size: 22.0,
        color: Colors.teal[600],
      );
    } else {
      return new Icon(
        Icons.done_all,
        size: 15.0,
        color: Colors.grey[400],
      );
    }
  }
}

//THIS RENDERS EMR
class EMRPage extends StatefulWidget {
  @override
  _EMRPageState createState() => new _EMRPageState();
}

class _EMRPageState extends State<EMRPage> {
  @override
  void initState() {
    super.initState();
  }

  final referenceToEMR = FirebaseDatabase.instance
      .reference()
      .child("DeXAutoCollect")
      .child("EMR")
      .child(_emailID.replaceAll(".", " "))
      .child(patientCode);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new IconButton(
            icon: new Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: new Text(patientCode.split("-")[0]),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          //add ability to collapse the list ie remove empty content
        ],
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new FirebaseAnimatedList(
              query: referenceToEMR,
              itemBuilder: (_, DataSnapshot snapshot,
                  Animation<double> animation, int i) {
                return textRenderForEMR(snapshot);
              },
//              sort: (a, b) => b.key.compareTo(a.key),
              defaultChild: new Center(child: new Text("Loading...")),
            ),
          ),
        ],
      ),
    );
  }

  //RENDER EMR UNITS NORMALLY OR DON'T SHOW THEM IF UNIT IS NULL
  Widget textRenderForEMR(snapshot) {
    if (snapshot.value["head"].toString() == "DATE") {
      return new Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Center(
          child: new Text(
            "------ "+snapshot.value["con"]+" ------",
            style: new TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    } else if (snapshot.value["con"].toString() != "") {
      return new Container(
        child: new Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(
                snapshot.value["head"],
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 14.0),
              ),
              new Text(
                snapshot.value["con"].toString(),
                style: new TextStyle(fontSize: 18.0),
              )
            ],
          ),
        ),
      );
    } else {
      return new Container();
    }
  }
}
