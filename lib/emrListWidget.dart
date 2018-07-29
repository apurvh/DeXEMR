import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  String usid;

  @override
  void initState() {
    getUsid();
    super.initState();
  }

  getUsid()async{
    await auth.currentUser().then((user){
      usid=user.uid;
      print("usid>> ${user.uid}");
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print("VALUE OF widget.email:====>  ${widget.email}");

    return new Scaffold(
      body: _recordsList(),
    );
  }

  //LIST OF PATIENT RECORDS FROM DB
  Widget _recordsList(){
    if(usid == null){
      return Center(child: new Text('loading(uid)...'),);
    }
    else{
      return StreamBuilder(
          stream: Firestore.instance.collection("listP").where(
              'usid', isEqualTo: usid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(child: const Text("Loading.."));
            else if (snapshot.data.documents.length == 0)
              return Center(
                  child: const Text("Empty List | Click +New to Add"));
            else {
              return ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  reverse: true,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return _buildListEMRItem(
                        context, snapshot.data.documents[index], index);
                  }
              );
            }
          }
      );
    }
  }

  _buildListEMRItem(context,document,index){
    print(">>index $index");

    DateTime datStamp = DateTime.fromMillisecondsSinceEpoch(document['ti']);

    return Column(
      children: <Widget>[
        ListTile(
          title: titleEMRListItem(document),
          subtitle: subtitleEMRListItem(document),
          leading: leadingEMRListItem(document),
          trailing: new Text(datStamp.day.toString()+'/'+datStamp.month.toString()+'/'+datStamp.year.toString()),
        ),
        Divider(),
      ],
    );
  }

//              //MATERIAL ROUTE TO EMR
//              Navigator
//                  .of(context)
//                  .push(new MaterialPageRoute(builder: (context) {
//                return new EMRPage(
//                  email: widget.email,
//                  patientCode: patientCode,
//                );
//              }));

  //saveAndTranscribe = 0 | Transcription is not required
  //saveAndTranscribe = 1 | Sent for transcription


  //RENDERS LEADING
  Widget leadingEMRListItem(document) {
    if(document['st']==0){
      return new Icon(Icons.cloud_queue);
    }
    else if (document['st']==1) {
      return new Icon(Icons.cloud_queue);
    }
    else if (document['st']==2) {
      return new Icon(
        Icons.done_all,
        size: 22.0,
        color: Colors.grey[400],
      );
    }
    else {
      return new Icon(
        Icons.done_all,
        size: 22.0,
        color: Colors.teal[600],
      );
    }
  }

  Widget subtitleEMRListItem(document) {
    if(document['st']==0){
      return new Text('Audio Saved | Processing..');
    }
    else if (document['st']==1) {
      return new Text('Audio Saved');
    }
    else if (document['st']==2) {
      return new Text('Transcribed | Verify');
    }
    else {
      return new Text(document['ph'].toString());
    }
  }

  Widget titleEMRListItem(document) {
    if(document['st']==0){
      return new Text('ID-'+document['ti'].toString(),style: TextStyle(fontWeight: FontWeight.bold),);
    }
    else if (document['st']==1) {
      return new Text(document['nn']+' '+document['ns'],style: TextStyle(fontWeight: FontWeight.bold),);
    }
    else if (document['st']==2) {
      return new Text(document['nn']+' '+document['ns'],style: TextStyle(fontWeight: FontWeight.bold),);
    }
    else {
      return new Text(document['nn']+' '+document['ns'],style: TextStyle(fontWeight: FontWeight.bold),);
    }
  }

}
