//import 'package:flutter/material.dart';
//import 'package:firebase_database/firebase_database.dart';
//import 'package:firebase_database/ui/firebase_animated_list.dart';
//
//
////AFTER CLICKING LIST ICON ON MAIN SCREEN
//class EMRListWidget extends StatefulWidget {
//  @override
//  _EMRListWidgetState createState() => new _EMRListWidgetState();
//}
//
//class _EMRListWidgetState extends State<EMRListWidget> {
//
//  BuildContext _scaffoldContext;
//
//  @override
//  Widget build(BuildContext context) {
//    return new Scaffold(
//      appBar: new AppBar(
//        title: new Text("Patient Records"),
//      ),
//      body: new Builder(builder: (BuildContext context) {
//        _scaffoldContext = context;
//        return _recordsList();
//      }),
//    );
//  }
//
//  final referenceToRecords = FirebaseDatabase.instance
//      .reference()
//      .child("DeXAutoCollect")
//      .child("list")
//      .child(_emailID.replaceAll(".", " "));
//
//  //LIST OF PATIENT RECORDS FROM DB
//  Widget _recordsList() {
//    return new Column(
//      children: <Widget>[
//        new Flexible(
//          child: new FirebaseAnimatedList(
//            query: referenceToRecords,
//            itemBuilder:
//                (_, DataSnapshot snapshot, Animation<double> animation, int i) {
//              return _recordsListTile(snapshot);
//            },
//            sort: (a, b) => b.key.compareTo(a.key),
//            defaultChild: new Center(child: new Text("loading..")),
//          ),
//        ),
//      ],
//    );
//  }
//
//  Widget _recordsListTile(snapshot) {
//    if (snapshot.value["conversionStatus"] == 0) {
//      return new Column(
//        children: <Widget>[
//          new ListTile(
//              leading: new Icon(
//                Icons.cached,
//                size: 15.0,
//                color: Colors.grey[400],
//              ),
//              title: new Text(
//                snapshot.value["name"].toString().split(".")[0],
//                style: new TextStyle(color: Colors.grey[600]),
//              ),
//              trailing: new Text(
//                snapshot.value["dateStamp"],
//                style: new TextStyle(color: Colors.grey[600]),
//              )),
//          new Divider(),
//        ],
//      );
//    } else {
//      return new Column(
//        children: <Widget>[
//          new ListTile(
//            leading: colorOfTick(snapshot),
//            title: new Text(
//              snapshot.value["newName"],
//              style: new TextStyle(
//                  color: Colors.grey[900], fontWeight: FontWeight.bold),
//            ),
//            trailing: new Text(
//              snapshot.value["dateStamp"],
//              style: new TextStyle(color: Colors.grey[800]),
//            ),
//            onTap: () {
//              //GET KEY AND PASS IT
//              patientKey = snapshot.key;
//              print("patientKey: " + patientKey);
//              referenceToRecords.child(patientKey).update({"seen": 1});
//
//              //SET PATIENT CODE WHICH IS USED TO LAOD PATIENT EMR
//              patientCode = snapshot.value["newName"] +
//                  "-" +
//                  snapshot.value["phone"].toString();
//              print("Redirected to EMR and patientCode: " + patientCode);
//
//              //MATERIAL ROUTE TO EMR
//              Navigator
//                  .of(context)
//                  .push(new MaterialPageRoute(builder: (context) {
//                return new EMRPage();
//              }));
//            },
//          ),
//          new Divider(),
//        ],
//      );
//    }
//  }
//
//  //RENDERS COLOR OF TICK IN RECORDS LIST
//  Widget colorOfTick(snapshot) {
//    if (snapshot.value["seen"] == 1) {
//      return new Icon(
//        Icons.done_all,
//        size: 22.0,
//        color: Colors.teal[600],
//      );
//    } else {
//      return new Icon(
//        Icons.done_all,
//        size: 15.0,
//        color: Colors.grey[400],
//      );
//    }
//  }
//}
