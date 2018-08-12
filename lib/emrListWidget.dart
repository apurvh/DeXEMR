import 'package:flutter/material.dart';
//import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dex_for_doctor/emrWidget.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    //check for previous upload crash
    _checkforCrashedAudio();
    super.initState();
  }

  _checkforCrashedAudio() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();

    bool whetherDeXDirExists = false;
    await new Directory(appDocDirectory.path+'/'+'DeX')
        .exists().then((what){
          whetherDeXDirExists=what;
    });
    if(whetherDeXDirExists) {
      new Directory(appDocDirectory.path + '/' + 'DeX')
          .list(recursive: true)
          .toList()
          .then((listOFDirContent) {
        print("DeX directoty >>>>Length: ${listOFDirContent.length} ---CONTENT: $listOFDirContent");
        if (listOFDirContent.length > 0) {
          for (int h = 0; h < listOFDirContent.length; h++) {
            reUploadCrashedAudio(listOFDirContent[h]);
//            print(listOFDirContent[0].path.substring(listOFDirContent[0].path.length - 21));
          }
        } else {
          print('>>>No redundant audio');
//          String hodor='/data/user/0/dextechnologies.dexfordoctor/app_flutter/DeX/DeX-1533050241023.m4a';
//          print(hodor.substring(hodor.length-21,hodor.length));

        }
      });
    }
    else{
      print('>>>No Audio directory yet');
    }
  }

  reUploadCrashedAudio(tobeUploadedFile) async{
    print("Attempting to Upload again: $tobeUploadedFile");
//    print("Attempting to Upload again: ${tobeUploadedFile
//        .toString()
//        .substring(tobeUploadedFile.toString().length - 21)}");

    StorageReference refOfCA = FirebaseStorage.instance
        .ref()
        .child("Audio")
        .child(usid)
        .child(tobeUploadedFile
        .toString()
        .substring(tobeUploadedFile.toString().length - 22,tobeUploadedFile.toString().length-1));

    File rfile = new File(tobeUploadedFile.path);
    StorageUploadTask uploadTask = refOfCA.putFile(rfile);
    Uri fileUrl = (await uploadTask.future).downloadUrl;

    //Delete File
    await uploadTask.future.whenComplete((){
      print(">>Upload COmplete==> $tobeUploadedFile");

      rfile.deleteSync(recursive: true);

      print(">>File is DELETED");
    });

  }

  getUsid() async {
    await auth.currentUser().then((user) {
      usid = user.uid;
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
  Widget _recordsList() {
    if (usid == null) {
      return Center(
        child: new Text('loading(uid)...'),
      );
    } else {
      return StreamBuilder(
          stream: Firestore.instance
              .collection("listP")
              .where('usid', isEqualTo: usid)
              .snapshots(),
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
                  });
            }
          });
    }
  }

  _buildListEMRItem(context, document, index) {
//    print(">>index $index");

    DateTime datStamp = DateTime.fromMillisecondsSinceEpoch(document['ti']);

    return Column(
      children: <Widget>[
        ListTile(
          title: titleEMRListItem(document),
          subtitle: subtitleEMRListItem(document),
          leading: leadingEMRListItem(document),
          trailing: new Text(datStamp.day.toString() +
              '/' +
              datStamp.month.toString() +
              '/' +
              datStamp.year.toString()),
          onTap: () {
            //MATERIAL ROUTE TO EMR
            onTapEMRListItem(document);
          },
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

  //saveAndTranscribe = 0 | just save
  //saveAndTranscribe = 1 | save and transcribe

  //st = 0 | for no conversion
  //st = 1 | for just name conversion (Unpaid)
  //st = 2 | for complete conversion
  //st = 0 | for complete conversion with Read/verified

  //RENDERS LEADING
  Widget leadingEMRListItem(document) {
    if (document['st'] == 0) {
      return new Icon(Icons.cloud_queue);
    } else if (document['st'] == 1) {
      return new Icon(Icons.cloud_queue);
    } else if (document['st'] == 2) {
      return new Icon(
        Icons.done_all,
        size: 22.0,
        color: Colors.grey[400],
      );
    } else if (document['st'] == 8) {
      return new Icon(Icons.cloud_queue);
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
    if (document['st'] == 0) {
      return new Text('Audio Saved | Processing..');
    } else if (document['st'] == 1) {
      return new Text('Audio Saved');
    } else if (document['st'] == 2) {
      return new Text('Transcribed | Verify');
    } else if (document['st'] == 8) {
      return new Text('Transcribing..');
    }
    else {
      return new Text(document['ph'].toString());
    }
  }


  //CAREFULL about st having other values
  Widget titleEMRListItem(document) {
    if (document['st'] == 0) {
      return new Text(
        'ID-' + document['ti'].toString(),
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (document['st'] == 1) {
      return new Text(
        document['nn'] + ' ' + document['ns'],
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (document['st'] == 2) {
      return new Text(
        document['nn'] + ' ' + document['ns'],
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (document['st'] == 8) {
      return new Text(
        'ID-' + document['ti'].toString(),
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }
    else {
      return new Text(
        document['nn'] + ' ' + document['ns'],
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  onTapEMRListItem(document) {
    if (document['st'] == 2 || document['st'] == 3) {

      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new EMRPage(
          name: document['nn'],
          sname: document['ns'],
          phnumber: document['ph'],
          usid: document['usid'],
        );
      }));
    } else {
      print('>>Empty');
    }
  }
}
