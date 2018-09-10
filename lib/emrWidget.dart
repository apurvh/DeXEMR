import 'package:flutter/material.dart';
//import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayer/audioplayer.dart';
//import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'dart:async';
//import 'package:share/share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
//import 'package:firebase_auth/firebase_auth.dart';


//THIS RENDERS EMR
class EMRPage extends StatefulWidget {
  const EMRPage({Key key, this.name, this.sname, this.phnumber, this.usid, this.analytics, this.observer});

  final String usid;
  final String name;
  final String sname;
  final String phnumber;

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;

  @override
  _EMRPageState createState() => new _EMRPageState();
}

class _EMRPageState extends State<EMRPage> {
  AudioPlayer audioPlayer = new AudioPlayer();


  PageController pageXController;
  int currentPage = 0;
  int countPage;

//  var referenceToEMR;
  BuildContext cccContext;
  @override
  void initState() {
    super.initState();
    pageXController = new PageController(
      initialPage: currentPage,
      keepPage: false,
      viewportFraction: 0.95,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.teal[800],
        leading: new IconButton(
            icon: new Icon(Icons.close),
            onPressed: () {
//              if (audioFileWidgetState == 1) stopSound();
              Navigator.pop(context);
            }),
        title:
            new Text(widget.name + ' ' + widget.sname),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          ///ADDING number of transcription
//          Padding(
//            padding: const EdgeInsets.symmetric(vertical: 18.0),
//            child: new Text(
//              (currentPage+1).toString()+"/"+countPage.toString(),
//              style: TextStyle(color: Colors.white),
//            ),
//          ),
          new IconButton(
              icon: new Icon(Icons.share),
              onPressed: () {
//                shareButton();
              }),

        ],
      ),
      body:

      new Center(
        child: new Container(
          color: Colors.blueGrey[50],
          child: new PageView.builder(
              onPageChanged: (value) {
                setState(() {
                  currentPage = value;
                });
              },
              controller: pageXController,
              itemCount: countPage,
              itemBuilder: (context, index)=>builderX(index)

          ),
        ),
      ),

//      Builder(builder: (context){
//        cccContext=context;
//        return new Column(
//          children: <Widget>[
//            new StreamBuilder(
//              stream: Firestore.instance
//                  .collection("ptsP")
//                  .where('usid', isEqualTo: widget.usid)
//                  .where('nn', isEqualTo: widget.name)
//                  .where('ns', isEqualTo: widget.sname)
//                  .where('ph', isEqualTo: widget.phnumber)
//                  .snapshots(),
//              builder: (context, snapshot) {
//                if (!snapshot.hasData)
//                  return Center(child: Center(child: const Text("Loading..")));
//                return _emrPageRender(context, snapshot.data.documents[0]);
//              },
//            ),
//          ],
//        );
//      }),


      floatingActionButton: feedBackButton(),
    );
  }


  ///build Carausal
  builderX(int index) {
    return new AnimatedBuilder(
      animation: pageXController,
      builder: (context, child) {
        double value = 1.0;
        if (pageXController.position.haveDimensions) {
          value = pageXController.page - index;
          value = (1 - (value.abs() * .2)).clamp(0.0, 1.0);
        }
        print('value $value');
        return new Center(
          child: new SizedBox(
            height: Curves.easeOut.transform(value) * 800,
            width: Curves.easeOut.transform(value) * 500,
            child: child,
          ),
        );
      },
      child: new Container(
        margin: const EdgeInsets.only(right: 10.0,top: 5.0,bottom: 5.0),
        decoration: new BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.teal,blurRadius: 0.0,spreadRadius: 0.0)],

        ),
        child:

        Builder(builder: (context){
        cccContext=context;
        return new Column(
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
                countPage=snapshot.data.documents.length;
                print('countPage : $countPage');
                return _emrPageRender(context, snapshot.data.documents[currentPage]);
              },
            ),
          ],
        );
      }),

      ),
    );
  }


  Widget feedBackButton(){
    if(currentPage==0)
    return RawMaterialButton(onPressed: (){feedbackDoctorRoute();_verifyEventLog();},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.done_all,color: Colors.blue[800],),
          Text(' VERIFY/FEEDBACK',style: TextStyle(color: Colors.blue[800]),),
        ],
      ),

    );
    else return Container();
  }

  ///ADD 40 POINTS TO SCR
  ///ADD FEEDBACK TEXT FBK BY DOCTOR
  ///ADD ACCURACY FEEDBACK BY DOCTOR
  TextEditingController feedbackController = new TextEditingController();



  feedbackDoctorRoute(){
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('  Verify/Corrections',style: TextStyle(fontWeight: FontWeight.bold),),
                  IconButton(icon: Icon(Icons.close), onPressed: () {
                    Navigator.pop(context);
                  })
                ],
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new LoadListOfHeading(name: widget.name,sname: widget.sname,phnumber: widget.phnumber,usid: widget.usid,currentPage: currentPage,),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: collectFF(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(onPressed: (){feedBackSubmit();Navigator.pop(context);}, child: Text('Submit')),
              ),
            ],
          ),
        ),
      );
    }));
  }




//  feedBackDoctor(){
//    return showDialog(
//      barrierDismissible: false,
//      context: context,
//      child: new AlertDialog(
//        title: Text(
//          'Verify/Feedback',
//        ),
//        content: collectFF(),
//        actions: <Widget>[
//          FlatButton(onPressed: (){Navigator.pop(context);}, child: Text('Not now')),
//          FlatButton(onPressed: (){feedBackSubmit();Navigator.pop(context);}, child: Text('Submit')),
//        ],
//      ),
//    );
//  }

  Widget collectFF(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

//        Text('Feedback: '),
        new TextFormField(
          decoration: new InputDecoration(
            labelText: 'Add any corrections here...',
          ),
          keyboardType: TextInputType.multiline,
          controller: feedbackController,
          maxLines: 8,
        ),
//        Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.done_all),
              Text(' Transcription Verified'),
            ],
          ),
        ),
      ],
    );
  }

  feedBackSubmit()async {

    Scaffold.of(cccContext).showSnackBar(new SnackBar(
      content: new Text(
        "Submitting...",
        style: TextStyle(fontSize: 20.0),
      ),
      duration: new Duration(seconds: 4),
    ));

    ///Add 40 points to scr
    ///First get value
    int scrValueBeforeFeedback;
    String scrValueBeforeFeedbackKey;
    await Firestore.instance.collection('listP')
        .where('usid',isEqualTo: widget.usid)
        .where('nn',isEqualTo: widget.name)
        .where('ns',isEqualTo: widget.sname)
        .where('ph',isEqualTo: widget.phnumber)
        .orderBy('ti',descending: true)
        .limit(1)
        .getDocuments()
        .then((doc){
      scrValueBeforeFeedback=doc.documents[0]['scr'];
      scrValueBeforeFeedbackKey=doc.documents[0].documentID;
    });
    ///Then add 40 points
    await Firestore.instance.collection('listP').document(scrValueBeforeFeedbackKey).updateData({
      'scr':scrValueBeforeFeedback+40,
    });

    String textFeedbackKey;
    ///Add the feedback text
    await Firestore.instance.collection('ptsP')
        .where('usid',isEqualTo: widget.usid)
        .where('nn',isEqualTo: widget.name)
        .where('ns',isEqualTo: widget.sname)
        .where('ph',isEqualTo: widget.phnumber)
        .orderBy('ti',descending: true)
        .limit(1)
        .getDocuments()
        .then((doc){
      textFeedbackKey=doc.documents[0].documentID;
    });
    await Firestore.instance.collection('ptsP').document(textFeedbackKey).updateData({
      'fdb':feedbackController.text,
    });
  }
  ///done



  _emrPageRender(context, document) {

    int aaage;
    if(!(document['dy'] == null)){
      aaage = DateTime.now().year - document['dy'];
    }

    String whenn = DateTime
        .fromMillisecondsSinceEpoch(document['ti'])
        .toLocal()
        .toString();

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[

          _emrPageTileRender("Name",
              document['nn'].toString() + ' ' + document['ns'].toString(),Colors.grey[50]),
          _emrPageTileRender("Phone", document['ph'].toString(),Colors.grey[50]),
          _emrPageTileRender("Age", aaage.toString(),Colors.grey[50]),
          _emrPageTileRender("Recorded On", whenn,Colors.grey[50]),
          _emrPageTileRender("Gender", document['ge'].toString(),Colors.grey[50]),

          _emrPageTileRender("Chief Complaint", document['cc'].toString(),Colors.grey[50]),
          _emrPageTileRender("Present History", document['ha'].toString(),Colors.grey[50]),
          _emrPageTileRender("Past History", document['hb'].toString(),Colors.grey[50]),
          _emrPageTileRender("Family History", document['hc'].toString(),Colors.grey[50]),
          _emrPageTileRender("Drug History", document['hd'].toString(),Colors.grey[50]),
          _emrPageTileRender("Allergy History", document['he'].toString(),Colors.grey[50]),
          _emrPageTileRender("Addictions", document['hf'].toString(),Colors.grey[50]),
          _emrPageTileRender(
              "Menstrual & Obsteric History", document['hg'].toString(),Colors.grey[50]),

          _emrPageTileRender("General Examination", document['eg'].toString(),Colors.grey[50]),
          _emrPageTileRender("Local Examiniation", document['el'].toString(),Colors.grey[50]),
          _emrPageTileRender("Diagnosis", document['di'].toString(),Colors.grey[50]),

          _emrPageTileRender("Investigations Advised", document['ia'].toString(),Colors.grey[50]),
          _emrPageTileRender("Investigations Done", document['id'].toString(),Colors.grey[50]),
          _emrPageTileRender("Treatment Plan", document['tp'].toString(),Colors.grey[50]),

          _emrPageTileRender("Prescription", document['pp'].toString(),Colors.grey[50]),
          _emrPageTileRender("Follow Up", document['fu'].toString(),Colors.grey[50]),
          _emrPageTileRender("Counselling", document['co'].toString(),Colors.grey[50]),

          _emrPageTileRender("Other Info", document['zz'].toString(),Colors.grey[50]),

          _emrPageTileRender("Special Info", document['spi'].toString(),Colors.red[100]),


          _emrPageTileRender("Feedback by Doctor", document['fdb'].toString(),Colors.yellowAccent[100]),


          _emrPageTileRender(" ", ' ',Colors.grey[50]),

        ],
      ),
    );
  }

  ///TODO check whether content '' is sufficient
  _emrPageTileRender(heading, content,bcolor) {
    if (content == "null" || content==''){
      return Container();
    }
    else {
      return Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: bcolor
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5.0,3.0,5.0,2.0),
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
                  textAlign: TextAlign.center,
                ),
                new Text(
                  content,
                  style: new TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

//
//  //share button email
////  Future shareButton() async {
////    Map shareData;
////    List shareDataList;
////    String shareDataText = "Medical Records of ${widget.patientCode} : \n\n";
////    await FirebaseDatabase.instance
////        .reference()
////        .child("DeXAutoCollect")
////        .child("EMR")
////        .child(widget.email.replaceAll(".", " "))
////        .child(widget.patientCode)
////        .once()
////        .then((DataSnapshot snap) {
////      print("shareData====>>>>${snap.value}");
////      shareData = snap.value;
////      shareDataList = shareData.values.toList();
////      print("shareDataList====>>>>${shareDataList}");
////    });
////    for (var i = 0; i < shareDataList.length - 1; i++) {
////      print("==============>${shareDataList[i]["head"]}");
////      String shareDataTextloopHead;
////      String shareDataTextloopCon;
////
////      shareDataTextloopHead = shareDataList[i]["head"].toString();
////      shareDataTextloopCon = shareDataList[i]["con"].toString();
////
////      //Remove Blanks
////      if (shareDataTextloopCon == "") {
////      } else {
////        shareDataText = shareDataText +
////            shareDataTextloopHead +
////            ": " +
////            shareDataTextloopCon +
////            "\n\n";
////      }
////    }
////    print("Snap value: ==>> $shareDataText");
////    Share.share(shareDataText);
////  }
//
//  int audioFileWidgetState = 0;
//  Future<Null> playSound(audioUrl) async {
//    await audioPlayer.play(audioUrl);
//  }
//
//  Future<Null> stopSound() async {
//    await audioPlayer.stop();
//  }
//
//  Widget audioFileWidget(snapshot) {
//    if (audioFileWidgetState == 0) {
//      return new FlatButton.icon(
//        icon: new Icon(
//          Icons.play_circle_outline,
//          size: 40.0,
//          color: Colors.blueGrey,
//        ),
//        label: new Text("Play"),
//        onPressed: () {
//          print("Audio File plaiyng: " + snapshot.value["con"]);
//          playSound(snapshot.value["con"]);
//          audioFileWidgetState = 1;
//          setState(() {});
//        },
//      );
//    } else {
//      return new FlatButton.icon(
//        icon: new Icon(
//          Icons.stop,
//          size: 40.0,
//          color: Colors.blueGrey,
//        ),
//        label: new Text("Stop"),
//        onPressed: () {
//          stopSound();
//          audioFileWidgetState = 0;
//          setState(() {});
//        },
//      );
//    }
//  }
//
//  //RENDER EMR UNITS NORMALLY OR DON'T SHOW THEM IF UNIT IS NULL
///*  Widget textRenderForEMR(snapshot) {
//    if (snapshot.value["head"].toString() == "DATE") {
//      return new Padding(
//        padding: const EdgeInsets.all(8.0),
//        child: new Center(
//          child: new Text(
//            "------ " + snapshot.value["con"] + " ------",
//            style: new TextStyle(color: Colors.grey[500]),
//          ),
//        ),
//      );
//    } else if (snapshot.value["head"].toString() == "AUDI") {
//      return new Padding(
//        padding: const EdgeInsets.only(top: 10.0, bottom: 20.0, left: 10.0),
//        child: new Column(
//          children: <Widget>[
//            new Row(
//              children: <Widget>[
//                new Text(
//                  "AUDIO FILE",
//                  style: new TextStyle(
//                      fontWeight: FontWeight.bold,
//                      color: Colors.teal,
//                      fontSize: 14.0),
//                ),
//              ],
//            ),
//            audioFileWidget(snapshot),
//          ],
//        ),
//      );
//    } else if (snapshot.value["con"].toString() != "") {
//      return new Container(
//        child: new Padding(
//          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
//          child: new Column(
//            mainAxisAlignment: MainAxisAlignment.start,
//            crossAxisAlignment: CrossAxisAlignment.start,
//            children: <Widget>[
//              new Text(
//                snapshot.value["head"],
//                style: new TextStyle(
//                    fontWeight: FontWeight.bold,
//                    color: Colors.teal,
//                    fontSize: 14.0),
//              ),
//              new Text(
//                snapshot.value["con"].toString(),
//                style: new TextStyle(fontSize: 18.0),
//              )
//            ],
//          ),
//        ),
//      );
//    } else {
//      return new Container();
//    }
//  }*/
//
  ///Login Tracking via firebase analytics
  Future<Null> _verifyEventLog() async {

      await widget.analytics.logEvent(
        name: 'verifyAndFeedback',
      );
      print('logEvent-_verifyEventLog succeeded | ${new DateTime.now()}');
    }

}


class LoadListOfHeading extends StatefulWidget {

  const LoadListOfHeading({Key key,  this.name, this.sname, this.phnumber, this.usid,this.currentPage});

  final String usid;
  final String name;
  final String sname;
  final String phnumber;
  final int currentPage;


  @override
  _LoadListOfHeadingState createState() => _LoadListOfHeadingState();
}

class _LoadListOfHeadingState extends State<LoadListOfHeading> {

  List<String> loadSuggestionsList=['Loading'];

  @override
  void initState() {
    loadSuggestions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'Following Data can be added: '+loadSuggestionsList.toString(),
          style: TextStyle(color: Colors.teal),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Divider(),
        ),
      ],
    );
  }

  int loadSuggestionsApproval = 0;
  int setStateO = 0;
  loadSuggestions() async {
    print("....loadSuggestions Running");
    await Firestore.instance
        .collection('ptsP')
        .where('usid', isEqualTo: widget.usid)
        .where('nn', isEqualTo: widget.name)
        .where('ns', isEqualTo: widget.sname)
        .where('ph', isEqualTo: widget.phnumber)
        .getDocuments()
        .then((doc) {
          loadSuggestionsList.clear();
      print('....${doc.documents[0].data}');
      if (doc.documents[widget.currentPage]['dy'] == null) loadSuggestionsList.add('Age');
      if (doc.documents[widget.currentPage]['cc'] == '')
        loadSuggestionsList.add('Chief Complaint');

      if (doc.documents[widget.currentPage]['ha'] == '')
        loadSuggestionsList.add('Present History');
      if (doc.documents[widget.currentPage]['hb'] == '') loadSuggestionsList.add('Past History');
      if (doc.documents[widget.currentPage]['hc'] == '')
        loadSuggestionsList.add('Family History');
      if (doc.documents[widget.currentPage]['hd'] == '') loadSuggestionsList.add('Drug History');
      if (doc.documents[widget.currentPage]['he'] == '')
        loadSuggestionsList.add('Allergy History');
      if (doc.documents[widget.currentPage]['hf'] == '') loadSuggestionsList.add('Addictions');

      if (doc.documents[widget.currentPage]['el'] == '')
        loadSuggestionsList.add('Local Examiniation');

      if (doc.documents[widget.currentPage]['di'] == '') loadSuggestionsList.add('Diagnosis');
      if (doc.documents[widget.currentPage]['id'] == '')
        loadSuggestionsList.add('Investigations Done');

      if (doc.documents[widget.currentPage]['tp'] == '')
        loadSuggestionsList.add('Treatment Plan');
      if (doc.documents[widget.currentPage]['co'] == '') loadSuggestionsList.add('Counselling');

      if (doc.documents[widget.currentPage]['fdb'] == null) loadSuggestionsApproval = 1;
    });

    if (setStateO == 0)
      setState(() {
        setStateO = 1;
      });
  }
}

