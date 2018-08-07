import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dex_for_doctor/mainScreen.dart';

final auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();

String _emailID;

int googleSilentChecker = 0;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DeX - EMR',
      theme: new ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: new MyHomePage(title: 'DeX - EMR'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    print("GoogleSignIn: " + googleSignIn.currentUser.toString());

    if (googleSignIn.currentUser == null) {
      return new LoginWidget();
    } else {
      return new MainScreen(
        email: _emailID,
      );
    }
  }
}

//LOGIN FLOW
class LoginWidget extends StatefulWidget {
  @override
  _LoginWidgetState createState() => new _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: new AssetImage("assets/DeXXX.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Container(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: new Text(
                    "DeX",
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 70.0,
                      fontWeight: FontWeight.bold,
                      decorationStyle: TextDecorationStyle.double,
                    ),
                  ),
                ),
                decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: new Border.all(
                    color: Colors.blueGrey[50],
                    width: 2.0,
                  ),
                ),
              ),
              new Padding(
                padding: const EdgeInsets.only(top: 28.0),
                child: new Text(
                  "Collect Patient Records",
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
              new Text(
                "Simple | Fast | Secure",
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
              new Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: buttonThatControlsLoginGoogle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // START UP FUNCTIONS
  @override
  void initState() {
    super.initState();
    print("INIT STATE RUN");
    googleSilentCheckerFunction();
//    initPlatformState();
//    getPermissionAndroid();
//
//    messagingToken();
  }

  //CHECKS WHETHER USER IS ALREADY GOOGLE SIGNED
  Future googleSilentCheckerFunction() async {
    print("googleSilentCheckerFunction RUN");
    GoogleSignInAccount xUser = googleSignIn.currentUser;

//    localStorage = await SharedPreferences.getInstance();
//    //Get STATE OF LOGIN
//    loginStateStored = localStorage.getInt("loginInState");

    if (xUser == null) {
      xUser = await googleSignIn.signInSilently();
      if (xUser == null) {
        //failed
        googleSilentChecker = 2;
        setState(() {});
        print("googleSilentCheckerFunction RUN==>2 | NO GOOGLE ACC");
      } else {
        //success
        googleSilentChecker = 1;
        setState(() {});
        print("googleSilentCheckerFunction RUN==>1 | ACC EXITS");
        _emailID = googleSignIn.currentUser.email;

        //RESTART THE APP
        runApp(MyApp());

//        //UPDATE TOKEN TO CLOUD
//        FirebaseDatabase.instance
//            .reference()
//            .child("DeXAutoCollect")
//            .child("wallet")
//            .child(_emailID.replaceAll(".", " "))
//            .update({"token": tokenId});
//        print("FCM TOCKEN========>>>>>>>>>: uploaded successfully");
      }
    }
  }

  //THIS WIDGET RENDERS GOOGLE SIGN IN OR NOTHING USING STATE
  Widget buttonThatControlsLoginGoogle() {
    if (googleSilentChecker == 2) {
      return new Padding(
        padding: const EdgeInsets.only(top: 10.0),
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
//      await localStorage.setInt("loginInState", 1);
//      print("Wrote to shared pref local storage: login State: => 1");
    }
    print("ENSURE LOGGED IN SUCCESS: ");
    _emailID = googleSignIn.currentUser.email;

    //RESTART THE APP
    runApp(MyApp());

    setState(() {});
  }
}
