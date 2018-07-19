import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:dex_for_doctor/emrWidget.dart';
import 'dart:async';

final auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();

//AFTER CLICKING LIST ICON ON MAIN SCREEN
class EMRListWidget extends StatefulWidget {
  const EMRListWidget({Key key, this.email});

  final String email;

  @override
  _EMRListWidgetState createState() => new _EMRListWidgetState();
}

class _EMRListWidgetState extends State<EMRListWidget> {
  var referenceToRecords;

  @override
  void initState() {
    databaseRedundancy();
    referenceToRecords = FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(widget.email.replaceAll(".", " "));
    FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(widget.email.replaceAll(".", " "))
        .keepSynced(true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("VALUE OF widget.email:====>  ${widget.email}");

    return new Scaffold(
      body: _recordsList(),
    );
  }

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
            defaultChild: new Center(
              child: new Text("loading..."),
            ),
          ),
        ),
      ],
    );
  }

  //saveAndTranscribe = 0 | Transcription is not required
  //saveAndTranscribe = 2 | Transcription is not required but name is populated
  //saveAndTranscribe = 1 | Sent for transcription

  Widget _recordsListTile(snapshot) {
    if (snapshot.value["saveAndTranscribe"] == 0) {
      return new Column(
        children: <Widget>[
          new ListTile(
              leading: new Icon(
                Icons.play_arrow,
                size: 15.0,
                color: Colors.grey[400],
              ),
              title: new Text(
                snapshot.value["name"].toString().split(".")[0],
                style: new TextStyle(color: Colors.grey[700], fontSize: 14.0),
              ),
              subtitle: new Text(
                "Saved Audio",
                style: new TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
              trailing: new Text(
                snapshot.value["dateStamp"].toString().split(" ")[0],
                style: new TextStyle(color: Colors.grey[600]),
              )),
          new Divider(),
        ],
      );
    } else if (snapshot.value["saveAndTranscribe"] == 2) {
      return new Column(
        children: <Widget>[
          new ListTile(
              leading: new Icon(
                Icons.play_arrow,
                size: 15.0,
                color: Colors.grey[400],
              ),
              title: new Text(
                snapshot.value["newName"].toString(),
                style: new TextStyle(color: Colors.grey[800], fontSize: 14.0),
              ),
              subtitle: new Text(
                "Saved Audio",
                style: new TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
              trailing: new Text(
                snapshot.value["dateStamp"].toString().split(" ")[0],
                style: new TextStyle(color: Colors.grey[600]),
              )),
          new Divider(),
        ],
      );
    } else if (snapshot.value["conversionStatus"] == 0) {
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
                style: new TextStyle(color: Colors.grey[700], fontSize: 14.0),
              ),
              subtitle: new Text(
                "Processing...",
                style: new TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
              trailing: new Text(
                snapshot.value["dateStamp"].toString().split(" ")[0],
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
                  color: Colors.grey[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0),
            ),
            subtitle: new Text(
              snapshot.value["phone"].toString(),
              style: new TextStyle(color: Colors.grey[900], fontSize: 12.0),
            ),
            trailing: new Text(
              snapshot.value["dateStamp"].toString().split(" ")[0],
              style: new TextStyle(color: Colors.grey[800]),
            ),
            onTap: () {
              //GET KEY AND PASS IT
              String patientKey = snapshot.key;
              print("patientKey: " + patientKey);
              referenceToRecords.child(patientKey).update({"seen": 1});

              //SET PATIENT CODE WHICH IS USED TO LOAD PATIENT EMR
              String patientCode = snapshot.value["newName"] +
                  "-" +
                  snapshot.value["phone"].toString();
              print("Redirected to EMR and patientCode: " + patientCode);

              //MATERIAL ROUTE TO EMR
              Navigator
                  .of(context)
                  .push(new MaterialPageRoute(builder: (context) {
                return new EMRPage(
                  email: widget.email,
                  patientCode: patientCode,
                );
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

  Future<Null> databaseRedundancy() async {
    await FirebaseDatabase.instance.setPersistenceEnabled(true);
    await FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
//    FirebaseDatabase.instance.reference().keepSynced(true);
  }
}
