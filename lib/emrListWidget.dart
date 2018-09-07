import 'package:flutter/material.dart';
//import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dex_for_doctor/emrWidget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
    await new Directory(appDocDirectory.path + '/' + 'DeX')
        .exists()
        .then((what) {
      whetherDeXDirExists = what;
    });
    if (whetherDeXDirExists) {
      new Directory(appDocDirectory.path + '/' + 'DeX')
          .list(recursive: true)
          .toList()
          .then((listOFDirContent) {
        print(
            "DeX directoty >>>>Length: ${listOFDirContent.length} ---CONTENT: $listOFDirContent");
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
    } else {
      print('>>>No Audio directory yet');
    }
  }

  reUploadCrashedAudio(tobeUploadedFile) async {
    print("Attempting to Upload again: $tobeUploadedFile");
//    print("Attempting to Upload again: ${tobeUploadedFile
//        .toString()
//        .substring(tobeUploadedFile.toString().length - 21)}");

    StorageReference refOfCA = FirebaseStorage.instance
        .ref()
        .child("Audio")
        .child(usid)
        .child(tobeUploadedFile.toString().substring(
            tobeUploadedFile.toString().length - 22,
            tobeUploadedFile.toString().length - 1));

    File rfile = new File(tobeUploadedFile.path);
    StorageUploadTask uploadTask = refOfCA.putFile(rfile);
    Uri fileUrl = (await uploadTask.future).downloadUrl;

    //Delete File
    await uploadTask.future.whenComplete(() {
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

  ///LIST OF PATIENT RECORDS FROM DB
  Widget _recordsList() {
    if (usid == null) {
      return Center(
        child: new Text('loading(uid)...'),
      );
    } else {
      return StreamBuilder(
          stream: Firestore.instance
              .collection("listP")
              .where('usid',
                  isEqualTo:
                      usid) //Q0gDrO5Ol9QbNux6M7s4DqMwGi13 ppSNP5pZjheIkEFiNP764djBTE13 otXNQPALfhYi6Za6axCkFgE4G4J3
              .orderBy('ti', descending: true)
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
                  reverse: false,
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

    ///SHOW ENTRY ONLY IF 0,1,2,8
    ///FOR ANY OTHER NUMBER, DONT SHOW
    if (document['st'] == 0 ||
        document['st'] == 1 ||
        document['st'] == 2 ||
        document['st'] == 8) {
      return Column(
        children: <Widget>[
          ListTile(
            title: titleEMRListItem(document),
            subtitle: subtitleEMRListItem(document, datStamp),
            leading: leadingEMRListItem(document),
            trailing: trailEMRListItem(document),
            onTap: () {
              //MATERIAL ROUTE TO EMR
              onTapEMRListItem(document);
            },
          ),
          Divider(),
        ],
      );
    } else {
      return Container();
    }
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
  //st = 1 | for Uploading
  //st = 2 | for complete conversion
  //st = 2 | for complete conversion with Read/verified
  //st = 8 | for Transcribing

  ///RENDERS TRAILING
  Widget trailEMRListItem(document) {
    Color colorX;

    ///Logic to calc background color
    if (document['scr'] != null) {
      if (document['scr'] < 60)
        colorX = Colors.red;
      else if (document['scr'] > 59 && document['scr'] < 80)
        colorX = Colors.lightGreen[600];
      else if (document['scr'] > 79) colorX = Colors.blue[700];
    }

    if (document['ty'] == 1) {
      if (document['scr'] == null) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal,
          ),
          child: Text(
            '0',
            style: TextStyle(
              color: Colors.grey[100],
            ),
          ),
        );
      } else {
        return GestureDetector(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorX,
                boxShadow: [
                  BoxShadow(color: colorX, blurRadius: 1.0, spreadRadius: 0.0)
                ]),
            child: Text(
              document['scr'].toString(),
              style: TextStyle(
                color: Colors.grey[100],
              ),
            ),
          ),
          onTap: () {
            scoreInfo(document, colorX);
          },
        );
      }
    } else {
      return Icon(
        Icons.transform,
        color: Colors.blueGrey[50],
      );
    }
  }

  ///renders score info: Dialogue box
  scoreInfo(document, colorX) {
    double percentX = document['scr'] / 100;
    if (percentX > 1) percentX = 1.0;
//    loadSuggestions(document);

    return showDialog(
      context: context,
      child: new AlertDialog(
        title: Text(
          'Autogenerated Score',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 200,
              leading: Text(
                'Overall:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              animation: true,
              lineHeight: 16.0,
              percent: percentX,
              linearStrokeCap: LinearStrokeCap.butt,
              center: Text(
                document['scr'].toString() + '/100',
                style: TextStyle(color: Colors.grey[100]),
              ),
              progressColor: colorX,
              animationDuration: 2000,
            ),
            Text(
                'This score is automatically generated from the Data collected'),
            Divider(
              color: Colors.grey[900],
            ),
            Text(
              'To Improve Score: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            new ScoreInfo(
              document: document,
              colorX: colorX,
            )
//              suggestionAppWidget(),
//              suggestionListWidget(),
          ],
        ),
      ),
    );
  }

/*  ///load blank headings in list
  List<String> loadSuggestionsList =[];
  int loadSuggestionsApproval=0;
  loadSuggestions(document)async {
    loadSuggestionsList.clear();
    await Firestore.instance.collection('ptsP')
        .where('usid',isEqualTo: document['usid'])
        .where('nn',isEqualTo: document['nn'])
        .where('ns',isEqualTo: document['ns'])
        .where('ph',isEqualTo: document['ph'])
        .orderBy('ti',descending: true)
        .limit(1)
        .getDocuments()
        .then((doc){

          if(doc.documents[0]['dy']==null) loadSuggestionsList.add('Age');
          if(doc.documents[0]['cc']=='') loadSuggestionsList.add('Chief Complaint');

          if(doc.documents[0]['ha']=='') loadSuggestionsList.add('Present History');
          if(doc.documents[0]['hb']=='') loadSuggestionsList.add('Past History');
          if(doc.documents[0]['hc']=='') loadSuggestionsList.add('Family History');
          if(doc.documents[0]['hd']=='') loadSuggestionsList.add('Drug History');
          if(doc.documents[0]['he']=='') loadSuggestionsList.add('Allergy History');
          if(doc.documents[0]['hf']=='') loadSuggestionsList.add('Addictions');

          if(doc.documents[0]['el']=='') loadSuggestionsList.add('Local Examiniation');

          if(doc.documents[0]['di']=='') loadSuggestionsList.add('Diagnosis');
          if(doc.documents[0]['id']=='') loadSuggestionsList.add('Investigations Done');

          if(doc.documents[0]['tp']=='') loadSuggestionsList.add('Treatment Plan');
          if(doc.documents[0]['co']=='') loadSuggestionsList.add('Counselling');

          if(doc.documents[0]['fdb']==null) loadSuggestionsApproval=1;
    });
  }
  Widget suggestionListWidget(){
    if(loadSuggestionsList.length>0)
    return Text('-Include $loadSuggestionsList');
    else{
      return Container();
    }
  }
  Widget suggestionAppWidget(){
    if(loadSuggestionsApproval==1)
      return Text('-Approve/feedback');
    else{
      return Container();
    }
  }
  ///load blank headings in list -- done*/

  ///RENDERS LEADING
  Widget leadingEMRListItem(document) {
    if (document['st'] == 0) {
      return new Icon(
        Icons.cloud_queue,
        color: Colors.blueGrey[200],
      );
    } else if (document['st'] == 1) {
      return new SizedBox(
        child: new CircularProgressIndicator(
          valueColor: new AlwaysStoppedAnimation<Color>(Colors.blueGrey),
          strokeWidth: 3.0,
        ),
        width: 20.0,
        height: 20.0,
      );
//      return new Icon(
//        Icons.file_upload,
//        color: Colors.blueGrey[400],
//      );
    } else if (document['st'] == 2) {
      return new Icon(
        Icons.check_circle,
        size: 26.0,
        color: Colors.blueGrey[200],
      );
    } else if (document['st'] == 8) {
      return new Icon(
        Icons.cloud_queue,
        color: Colors.blueGrey[200],
      );
    } else {
      return new Icon(
        Icons.done_all,
        size: 22.0,
        color: Colors.teal[600],
      );
    }
  }

  Widget subtitleEMRListItem(document, datStamp) {
    if (document['st'] == 0) {
      return new Text('Audio Processing..');
    } else if (document['st'] == 1) {
      return new Text('Uploading Audio..');
    } else if (document['st'] == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Icon(
            Icons.date_range,
            color: Colors.grey[500],
            size: 16.0,
          ),
          new Text(
            ' ' +
                datStamp.day.toString() +
                '/' +
                datStamp.month.toString() +
                '/' +
                datStamp.year.toString(),
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      );
    } else if (document['st'] == 8) {
      return new Text('Transcribing..');
    } else {
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
        'ID-' + document['ti'].toString(),
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
    } else {
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

class ScoreInfo extends StatefulWidget {
  const ScoreInfo({this.document, this.colorX});

  final dynamic document;
  final Color colorX;

  @override
  _ScoreInfoState createState() => _ScoreInfoState();
}

class _ScoreInfoState extends State<ScoreInfo> {
  @override
  Widget build(BuildContext context) {
    double percentX = widget.document['scr'] / 100;
    if (percentX > 1) percentX = 1.0;
    loadSuggestions(widget.document);
    print("hhhhhhhhhhhhhhh");
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        suggestionAppWidget(),
        suggestionListWidget(),
      ],
    );
  }

  List<String> loadSuggestionsList = [];
  int loadSuggestionsApproval = 0;
  int setStateO = 0;
  loadSuggestions(document) async {
    loadSuggestionsList.clear();
    await Firestore.instance
        .collection('ptsP')
        .where('usid', isEqualTo: document['usid'])
        .where('nn', isEqualTo: document['nn'])
        .where('ns', isEqualTo: document['ns'])
        .where('ph', isEqualTo: document['ph'])
        .orderBy('ti', descending: true)
        .limit(1)
        .getDocuments()
        .then((doc) {
      if (doc.documents[0]['dy'] == null) loadSuggestionsList.add('Age');
      if (doc.documents[0]['cc'] == '')
        loadSuggestionsList.add('Chief Complaint');

      if (doc.documents[0]['ha'] == '')
        loadSuggestionsList.add('Present History');
      if (doc.documents[0]['hb'] == '') loadSuggestionsList.add('Past History');
      if (doc.documents[0]['hc'] == '')
        loadSuggestionsList.add('Family History');
      if (doc.documents[0]['hd'] == '') loadSuggestionsList.add('Drug History');
      if (doc.documents[0]['he'] == '')
        loadSuggestionsList.add('Allergy History');
      if (doc.documents[0]['hf'] == '') loadSuggestionsList.add('Addictions');

      if (doc.documents[0]['el'] == '')
        loadSuggestionsList.add('Local Examiniation');

      if (doc.documents[0]['di'] == '') loadSuggestionsList.add('Diagnosis');
      if (doc.documents[0]['id'] == '')
        loadSuggestionsList.add('Investigations Done');

      if (doc.documents[0]['tp'] == '')
        loadSuggestionsList.add('Treatment Plan');
      if (doc.documents[0]['co'] == '') loadSuggestionsList.add('Counselling');

      if (doc.documents[0]['fdb'] == null) loadSuggestionsApproval = 1;
    });

    if (setStateO == 0)
      setState(() {
        setStateO = 1;
      });
  }

  Widget suggestionListWidget() {
    if (loadSuggestionsList.length > 0)
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('-Include all info'),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 2.0, 15.0, 2.0),
            child: Text(
              '$loadSuggestionsList could not be captured from the audio.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      );
    else {
      return Container();
    }
  }

  Widget suggestionAppWidget() {
    if (loadSuggestionsApproval == 1)
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('-Verify/feedback'),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 2.0, 15.0, 2.0),
            child: Text(
              'Once the transcription is completed, we ask you to verify it and add relevant feedback.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      );
    else {
      return Container();
    }
  }
}
