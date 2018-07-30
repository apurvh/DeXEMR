import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'dart:async';
import 'package:share/share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//THIS RENDERS EMR
class EMRPage extends StatefulWidget {
  const EMRPage({Key key, this.name, this.sname, this.phnumber, this.usid});

  final String usid;
  final String name;
  final String sname;
  final String phnumber;

  @override
  _EMRPageState createState() => new _EMRPageState();
}

class _EMRPageState extends State<EMRPage> {
  AudioPlayer audioPlayer = new AudioPlayer();

  var referenceToEMR;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.teal[800],
        leading: new IconButton(
            icon: new Icon(Icons.close),
            onPressed: () {
              if (audioFileWidgetState == 1) stopSound();
              Navigator.pop(context);
            }),
        title:
            new Text(widget.name + ' ' + widget.sname),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.share),
              onPressed: () {
//                shareButton();
              })
        ],
      ),
      body: new Column(
        children: <Widget>[
          new StreamBuilder(
            stream: Firestore.instance
                .collection("ptsP")
                .where('usid', isEqualTo: widget.usid)
                .where('nn', isEqualTo: widget.name)
                .where('ns', isEqualTo: widget.sname)
                .where('ph', isEqualTo: widget.phnumber)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: Center(child: const Text("Loading..")));
              return _emrPageRender(context, snapshot.data.documents[0]);
            },
          ),
        ],
      ),
    );
  }

  _emrPageRender(context, document) {
    int aaage = DateTime.now().year - document['dy'];
    String whenn = DateTime
        .fromMillisecondsSinceEpoch(document['ti'])
        .toLocal()
        .toIso8601String();

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[

          _emrPageTileRender("Name",
              document['nn'].toString() + ' ' + document['ns'].toString()),
          _emrPageTileRender("Phone", document['ph'].toString()),
          _emrPageTileRender("Age", aaage.toString()),
          _emrPageTileRender("Recorded On", whenn),
          _emrPageTileRender("Gender", document['ge'].toString()),

          _emrPageTileRender("Chief Complaint", document['cc'].toString()),
          _emrPageTileRender("Present History", document['ha'].toString()),
          _emrPageTileRender("Past History", document['hb'].toString()),
          _emrPageTileRender("Family History", document['hc'].toString()),
          _emrPageTileRender("Drug History", document['hd'].toString()),
          _emrPageTileRender("Allergy History", document['he'].toString()),
          _emrPageTileRender("Addictions", document['hf'].toString()),
          _emrPageTileRender(
              "Menstrual & Obsteric History", document['hg'].toString()),

          _emrPageTileRender("General Examination", document['eg'].toString()),
          _emrPageTileRender("Local Examiniation", document['el'].toString()),
          _emrPageTileRender("Diagnosis", document['di'].toString()),

          _emrPageTileRender("Investigations Advised", document['di'].toString()),
          _emrPageTileRender("Investigations Done", document['di'].toString()),
          _emrPageTileRender("Treatment Plan", document['tp'].toString()),

          _emrPageTileRender("Prescription", document['pp'].toString()),
          _emrPageTileRender("Follow Up", document['fu'].toString()),
          _emrPageTileRender("Counselling", document['co'].toString()),

          _emrPageTileRender("Other Info", document['zz'].toString()),


        ],
      ),
    );
  }

  _emrPageTileRender(heading, content) {
    if (content == "null"){
      return Container();
    }
    else {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(
              heading,
              style: new TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                fontSize: 14.0,
              ),
            ),
            new Text(
              content,
              style: new TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      );
    }
  }

  //share button email
//  Future shareButton() async {
//    Map shareData;
//    List shareDataList;
//    String shareDataText = "Medical Records of ${widget.patientCode} : \n\n";
//    await FirebaseDatabase.instance
//        .reference()
//        .child("DeXAutoCollect")
//        .child("EMR")
//        .child(widget.email.replaceAll(".", " "))
//        .child(widget.patientCode)
//        .once()
//        .then((DataSnapshot snap) {
//      print("shareData====>>>>${snap.value}");
//      shareData = snap.value;
//      shareDataList = shareData.values.toList();
//      print("shareDataList====>>>>${shareDataList}");
//    });
//    for (var i = 0; i < shareDataList.length - 1; i++) {
//      print("==============>${shareDataList[i]["head"]}");
//      String shareDataTextloopHead;
//      String shareDataTextloopCon;
//
//      shareDataTextloopHead = shareDataList[i]["head"].toString();
//      shareDataTextloopCon = shareDataList[i]["con"].toString();
//
//      //Remove Blanks
//      if (shareDataTextloopCon == "") {
//      } else {
//        shareDataText = shareDataText +
//            shareDataTextloopHead +
//            ": " +
//            shareDataTextloopCon +
//            "\n\n";
//      }
//    }
//    print("Snap value: ==>> $shareDataText");
//    Share.share(shareDataText);
//  }

  int audioFileWidgetState = 0;
  Future<Null> playSound(audioUrl) async {
    await audioPlayer.play(audioUrl);
  }

  Future<Null> stopSound() async {
    await audioPlayer.stop();
  }

  Widget audioFileWidget(snapshot) {
    if (audioFileWidgetState == 0) {
      return new FlatButton.icon(
        icon: new Icon(
          Icons.play_circle_outline,
          size: 40.0,
          color: Colors.blueGrey,
        ),
        label: new Text("Play"),
        onPressed: () {
          print("Audio File plaiyng: " + snapshot.value["con"]);
          playSound(snapshot.value["con"]);
          audioFileWidgetState = 1;
          setState(() {});
        },
      );
    } else {
      return new FlatButton.icon(
        icon: new Icon(
          Icons.stop,
          size: 40.0,
          color: Colors.blueGrey,
        ),
        label: new Text("Stop"),
        onPressed: () {
          stopSound();
          audioFileWidgetState = 0;
          setState(() {});
        },
      );
    }
  }

  //RENDER EMR UNITS NORMALLY OR DON'T SHOW THEM IF UNIT IS NULL
/*  Widget textRenderForEMR(snapshot) {
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
    } else if (snapshot.value["head"].toString() == "AUDI") {
      return new Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 20.0, left: 10.0),
        child: new Column(
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Text(
                  "AUDIO FILE",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 14.0),
                ),
              ],
            ),
            audioFileWidget(snapshot),
          ],
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
  }*/
}
