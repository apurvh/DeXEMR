import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:share/share.dart';



final auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();

String _emailID;

//NAME TO BE USED TO LOAD PATIENT EMR
String patientCode;
String patientKey;

//STATES
int durationForDeletePrevious;
int stillUploadingLastOne;

//WALLET VALUE
int walletCurr = 0;
int walletAvail = 0;

int runOnceOnStartUp = 0;

SharedPreferences localStorage;


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

  int stateBtnDeletePrev = 0;

  BuildContext sssss;

  int loginStateStored;

  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  String tokenId;

  @override
  void initState() {
    super.initState();
    print("INIT STATE RUN");
    googleSilentCheckerFunction();
    initPlatformState();
    getPermissionAndroid();

    messagingToken();


  }

  //RETRIEVE AND SAVE TOKEN FOR NOTIFICATION
  Future messagingToken() async{
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          //THIS IS WHAT HAPPENS WHEN NOTIFICATION ARRIVES
          print("NOTIFICATION FROM FCM JUST ARRIVED");
          print(message);

        },
        onResume: (Map<String, dynamic> message) {
           print(message);
        },
        onLaunch: (Map<String, dynamic> message) {
          print(message);
    });

    await _firebaseMessaging.getToken().then((token) {
      tokenId = token;
    });

    print("FCM TOCKEN========>>>>>>>>>: "+tokenId+googleSignIn.currentUser.toString());

    //SAVE TOKEN ON CLOUD
//    if(!(googleSignIn.currentUser==null)){
//      FirebaseDatabase.instance.reference().child("DeXAutoCollect").child("wallet").child(_emailID.replaceAll(".", " ")).update({
//        "token":tokenId
//      });
//      print("FCM TOCKEN========>>>>>>>>>: pppppppppppppppppppppppppppppppppppppppppppppp");
//
//    }

  }

  String _platformVersion = 'Unknown';
  Permission permission;
  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SimplePermissions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }
  getPermissionAndroid() async{
    await SimplePermissions.checkPermission(Permission.RecordAudio).then((perm){
      print("permission State: $perm");
      if(perm==false){
        SimplePermissions.requestPermission(Permission.RecordAudio);
      }
    });
    await SimplePermissions.checkPermission(Permission.WriteExternalStorage).then((perm){
      print("permission State: $perm");
      if(perm==false){
        SimplePermissions.requestPermission(Permission.WriteExternalStorage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //CHECK CURRENT USER.. THIS STAYS NULL UNTIL SILENT LOGIN CHECKER ?
    print("Current User: " + googleSignIn.currentUser.toString());


    var signInStateValue;
    signInStateValue=googleSignIn.currentUser;

    if(loginStateStored==1){
      print("loginStateStored: $loginStateStored");
      signInStateValue = loginStateStored;
      print("signInStateValue: $signInStateValue");
    }

    if (signInStateValue == null ) {
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
      loadInitialValues(); //such as wallet values
      return new Scaffold(
          appBar: new AppBar(
            title: new Text(widget.title),
            actions: <Widget>[
//              new IconButton(
////                icon: new Icon(
////                  Icons.help_outline,
////                  color: Colors.grey[100],
////                ),
//                onPressed: () {},
//              ),
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
                  new Row(
                    children: <Widget>[
                      new FlatButton.icon(
                        label: new Text(walletCurr.toString() +
                            "/" +
                            walletAvail.toString()),
                        icon: new Icon(Icons.account_balance_wallet),
                        onPressed: () {},
                        textColor: Colors.blueGrey,
                      ),
                      new FlatButton.icon(
                        label: new Text("Records"),
                        icon: new Icon(Icons.library_books),
                        onPressed: () {
                          Navigator
                              .of(context)
                              .push(new MaterialPageRoute(builder: (context) {
                            return new ListScreen();
                          }));
                        },
                        textColor: Colors.blueGrey,
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(
                        bottom: 78.0, left: 10.0, right: 10.0),
                    child: new Divider(
                      color: Colors.blueGrey[300],
                    ),
                  ),
                  new RawMaterialButton(
                      splashColor: Colors.grey[100],
                      onPressed: () {
                        stateBtnDeletePrev = 1 + stateBtnDeletePrev;
                        _recordPauseSwitch = _recordPauseSwitch + 1;

                        //CHECK IF FOLLOWUP PATIENT
                        if (_recordPauseSwitch.isEven &&
                            _recordPauseSwitch != 0) {
                          alertTapToSaveCheckFollowupPatient();
                          setState(() {});
                        } else {
                          redButtonStateChannelFunction();
                          setState(() {});
                        }
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 18.0),
                      shape: new StadiumBorder(),
                      fillColor: Colors.grey[200],
                      child: redButtonOnPressed()),
                  new Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: redButtonOnPressed2(),
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: deletePrevious(),
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(
                        bottom: 0.0, left: 10.0, right: 10.0),
                    child: new Divider(
                      color: Colors.blueGrey[300],
                    ),
                  ),
                  new Row(
                    children: <Widget>[
                      new FlatButton.icon(
                          label:new Text("Reference",style: new TextStyle(fontStyle: FontStyle.italic,color: Colors.blueGrey,),),
                          icon: new Icon(
                            Icons.info_outline,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () {
                            showDialogFormat();
                          },
                      )
                    ],
                  )
                ],
              ),
            );
          }));
    }
  }


  //SHOWS ALL RECORD DOCUMENTATION FORMAT
  void showDialogFormat() {
    showDialog(
        context: context,
        child: new SimpleDialog(
          title: new Text("DeX listens for:",style: new TextStyle(color: Colors.teal),),
          children: <Widget>[
            new Divider(),
            new Text(
              "Demographics",
              style: new TextStyle(color: Colors.teal[600], fontSize: 16.0),
            ),
            new Text(
              "Name, Age, Gender, Phone\n",
              style: new TextStyle(color: Colors.grey[900], fontSize: 16.0),
            ),
            new Text(
              "History",
              style: new TextStyle(color: Colors.teal[600], fontSize: 16.0),
            ),
            new Text(
              "Chief Complaints, Present History, Past History, Drug History, Allergies, Addictions, Menstrual History, Obsteric History\n",
              style: new TextStyle(color: Colors.grey[900], fontSize: 15.0),
            ),
            new Text(
              "Examinations",
              style: new TextStyle(color: Colors.teal[600], fontSize: 16.0),
            ),
            new Text(
              "General Examination, Local Examination\n",
              style: new TextStyle(color: Colors.grey[900], fontSize: 15.0),
            ),
            new Text(
              "Diagnosis\n",
              style: new TextStyle(color: Colors.teal[600], fontSize: 16.0),
            ),
            new Text(
              "Management\n",
              style: new TextStyle(color: Colors.teal[600], fontSize: 15.0),
            ),
            new Text(
              "Prescriptions & Follow up\n",
              style: new TextStyle(color: Colors.grey[900], fontSize: 15.0),
            ),
          ],
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 30.0),
          titlePadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
        ));
  }



  //NOT FUTURE BUT STREAM
  Future loadInitialValues() async {
    if (runOnceOnStartUp == 0) {
      FirebaseDatabase.instance
          .reference()
          .child("DeXAutoCollect")
          .child("wallet")
          .child(_emailID.replaceAll(".", " "))
          .onValue
          .listen((Event eve) {
        print("Stream: " + eve.snapshot.value.toString());
        walletAvail = eve.snapshot.value["avail"];
        walletCurr = eve.snapshot.value["curr"];
        print("wallet values loaded==> $walletCurr / $walletAvail");

        setState(() {
          runOnceOnStartUp = 1;
        });
      });

    }
  }

  Future alertTapToSaveCheckFollowupPatient() async {
    return showDialog<Null>(
      context: sssss,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Is this a Followup Patient?'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[],
            ),
          ),
          actions: <Widget>[
            new FlatButton.icon(
              icon: new Icon(
                Icons.done_all,
                size: 35.0,
              ),
              label: new Text(
                'Yes',
                style: new TextStyle(fontSize: 25.0),
              ),
              onPressed: () {
                followUpStatus = 1;
                redButtonStateChannelFunction();
                Navigator.of(context).pop();
                Scaffold.of(sssss).showSnackBar(new SnackBar(
                      content: new Text(
                        "Uploading Audio File ...",
                      ),
                      duration: new Duration(seconds: 4),
                    ));
                updateWalletValue();
              },
              color: Colors.blueGrey[50],
            ),
            new FlatButton.icon(
              icon: new Icon(
                Icons.close,
                size: 35.0,
              ),
              label: new Text(
                'No',
                style: new TextStyle(fontSize: 25.0),
              ),
              onPressed: () {
                followUpStatus = 0;
                redButtonStateChannelFunction();
                Navigator.of(context).pop();
                Scaffold.of(sssss).showSnackBar(new SnackBar(
                      content: new Text(
                        "Uploading Audio File ...",
                      ),
                      duration: new Duration(seconds: 4),
                    ));
                updateWalletValue();
              },
              color: Colors.blueGrey[50],
            ),
          ],
        );
      },
    );
  }

  //UPDATE VALUE BY 1 EVERYTIME A RECORD IS SENT
  Future updateWalletValue() async {
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("wallet")
        .child(_emailID.replaceAll(".", " "))
        .once()
        .then((DataSnapshot snap) {
      walletCurr = snap.value["curr"];
    });

    walletCurr = walletCurr + 1;

    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("wallet")
        .child(_emailID.replaceAll(".", " "))
        .update({"curr": walletCurr});

    setState(() {});
  }

  Widget deletePrevious() {
    if (stateBtnDeletePrev == 0) {
      return Container(
        height: 20.0,
      );
    } else if (stateBtnDeletePrev.isOdd) {
      return Container(
//        child: new FlatButton.icon(
//          onPressed: (){
//
//            print("recordPauseValue==>>>: $_recordPauseSwitch");
//
//
//          },
//          icon: new Icon(Icons.pause,size: 40.0,),
//          label:new Text("Pause"),
//          color: Colors.grey[100],
//          textColor: Colors.red,
//
//        ),
      );
    } else {
      return new FlatButton(
        child: new Text(
          "Delete previous?",
          style: new TextStyle(
              fontStyle: FontStyle.italic, color: Colors.blueGrey[200]),
        ),
        onPressed: () {
          print("alert");
          if (stillUploadingLastOne == 1) {
            Scaffold.of(sssss).showSnackBar(new SnackBar(
                  content: new Text(
                    "Still Uploading last file..",
                  ),
                  duration: new Duration(seconds: 4),
                ));
          } else {
            alertDeletePrevious();
          }
        },
      );
    }
  }

  Future<Null> alertDeletePrevious() async {
    return showDialog<Null>(
      context: sssss,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirm:'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Delete previous recording?'),
//                new Text('Duration:'),
//                new Text(
//                  durationForDeletePrevious.toString() + " Seconds",
//                  style: TextStyle(color: Colors.red, fontSize: 25.0),
//                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Yes'),
              onPressed: () {
                deletePreviousFunction();
                stateBtnDeletePrev = 0;
                Scaffold.of(sssss).showSnackBar(new SnackBar(
                      content: new Text(
                        "Deleted...",
                      ),
                      duration: new Duration(seconds: 4),
                    ));

                Navigator.of(context).pop();
                setState(() {});
              },
            ),
            new FlatButton(
              child: new Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future deletePreviousFunction() async {
    String snapShotKeyToDel;
    //get key
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(_emailID.replaceAll(".", " "))
        .limitToLast(1)
        .once()
        .then((DataSnapshot snapshot) {
      Map map = snapshot.value;
      snapShotKeyToDel = map.keys.toList()[0].toString();
      print("Deleting: " + snapShotKeyToDel);
    });

    //delete node by key
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(_emailID.replaceAll(".", " "))
        .child(snapShotKeyToDel)
        .remove();

    //deleting upload file from storage
//    print("file location: ")
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
      await localStorage.setInt("loginInState", 1);
      print("Wrote to shared pref local storage: login State: => 1");
    }
    print("ENSURE LOGGED IN SUCCESS: ");
    _emailID = googleSignIn.currentUser.email;
    setState(() {});
  }

  //CHECKS WHTHER USER IS ALREADY GOOGLE SIGNED
  Future googleSilentCheckerFunction() async {
    print("googleSilentCheckerFunction RUN");
    GoogleSignInAccount xUser = googleSignIn.currentUser;

    localStorage= await SharedPreferences.getInstance();
    //Get STATE OF LOGIN
    loginStateStored=localStorage.getInt("loginInState");

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

        //UPDATE TOKEN TO CLOUD
        FirebaseDatabase.instance.reference().child("DeXAutoCollect").child("wallet").child(_emailID.replaceAll(".", " ")).update({
          "token":tokenId
        });
        print("FCM TOCKEN========>>>>>>>>>: uploaded successfully");
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

    stillUploadingLastOne = 1;

    //GET KEY
    String uploadAudioFileKey=FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(_emailID.replaceAll(".", " "))
        .push().key;

//    print(uploadAudioFileKey);
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(_emailID.replaceAll(".", " "))
        .child(uploadAudioFileKey)
        .update({
      "name": result.substring(result.length - 21),
      "conversionStatus": 0,
      "followUp": followUpStatus,
      "dateStamp": new DateFormat.yMd().format(new DateTime.now())
    });

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
      await FirebaseDatabase.instance
          .reference()
          .child("DeXAutoCollect")
          .child("list")
          .child(_emailID.replaceAll(".", " "))
          .child(uploadAudioFileKey)
          .update({
        "url": fileUrl.toString(),
      });
      _valueOfSwicth = false;
    }
    stillUploadingLastOne = 0;
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
      durationForDeletePrevious = stopWatch.elapsed.inSeconds;
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
      return new Container(
//        child: new Column(
//          children: <Widget>[
//            new SwitchListTile(
//                title: new Text(
//                  'Previous/Followup patient',
//                  style: new TextStyle(color: Colors.teal),
//                ),
//                activeColor: Colors.teal,
//                secondary: new Icon(
//                  Icons.first_page,
//                  color: Colors.teal,
//                ),
//                value: _valueOfSwicth,
//                onChanged: (bool value) {
//                  _onSwitchChanged(value);
//                })
//          ],
//        ),
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

  AudioPlayer audioPlayer = new AudioPlayer();
  
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
              if(audioFileWidgetState==1)stopSound();
              Navigator.pop(context);
            }),
        title: new Text(patientCode.split("-")[0]),
        automaticallyImplyLeading: false,
        actions: <Widget>[

          new IconButton(icon: new Icon(Icons.share), onPressed: (){

            shareButton();

          })
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


  //share button email
  Future shareButton() async{

    List shareData;
    String shareDataText="Medical Records of $patientCode : \n\n";
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("EMR")
        .child(_emailID.replaceAll(".", " "))
        .child(patientCode).once().then((DataSnapshot snap){
          shareData=snap.value;
    });
    for (var i=0; i<shareData.length-1;i++){

      print("==============>${shareData[i]["head"]}");
      String shareDataTextloopHead;
      String shareDataTextloopCon;

        shareDataTextloopHead=shareData[i]["head"].toString();
        shareDataTextloopCon = shareData[i]["con"].toString();

      //Remove Blanks
      if(shareDataTextloopCon==""){}else{
        shareDataText = shareDataText + shareDataTextloopHead + ": " + shareDataTextloopCon + "\n\n";
      }
    }
    print("Snap value: ==>> $shareDataText");
    Share.share(shareDataText);
  }





  int audioFileWidgetState=0;
  Future<Null> playSound(audioUrl) async {
    await audioPlayer.play(audioUrl);
  }
  Future<Null> stopSound() async {
    await audioPlayer.stop();
  }
  Widget audioFileWidget(snapshot){

    if(audioFileWidgetState==0){
      return new FlatButton.icon(
        icon: new Icon(Icons.play_circle_outline,size: 40.0,color: Colors.blueGrey,),
        label: new Text("Play"),
        onPressed:(){
          print("Audio File plaiyng: "+snapshot.value["con"]);
          playSound(snapshot.value["con"]);
          audioFileWidgetState=1;
          setState(() {

          });
        },);
    }
    else{
      return new FlatButton.icon(
        icon: new Icon(Icons.stop,size: 40.0,color:Colors.blueGrey,),
        label: new Text("Stop"),
        onPressed:(){
          stopSound();
          audioFileWidgetState=0;
          setState(() {

          });
        },);
    }
  }








  //RENDER EMR UNITS NORMALLY OR DON'T SHOW THEM IF UNIT IS NULL
  Widget textRenderForEMR(snapshot) {
    if (snapshot.value["head"].toString() == "DATE") {
      return new Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Center(
          child: new Text(
            "------ " + snapshot.value["con"] + " ------",
            style: new TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    } else if(snapshot.value["head"].toString() == "AUDI"){
      return new Padding(
        padding: const EdgeInsets.only(top: 10.0,bottom: 20.0,left: 10.0),
        child: new Column(
          children: <Widget>[
            new Row(children: <Widget>[
              new Text("AUDIO FILE",style: new TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            fontSize: 14.0),),
            ],),
            audioFileWidget(snapshot),
          ],
        ),
      );
    }
    else if (snapshot.value["con"].toString() != "") {
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
