////THIS RENDERS EMR
//class EMRPage extends StatefulWidget {
//  @override
//  _EMRPageState createState() => new _EMRPageState();
//}
//
//class _EMRPageState extends State<EMRPage> {
//  AudioPlayer audioPlayer = new AudioPlayer();
//
//  @override
//  void initState() {
//    super.initState();
//  }
//
//  final referenceToEMR = FirebaseDatabase.instance
//      .reference()
//      .child("DeXAutoCollect")
//      .child("EMR")
//      .child(_emailID.replaceAll(".", " "))
//      .child(patientCode);
//
//  @override
//  Widget build(BuildContext context) {
//    return new Scaffold(
//      appBar: new AppBar(
//        leading: new IconButton(
//            icon: new Icon(Icons.close),
//            onPressed: () {
//              if (audioFileWidgetState == 1) stopSound();
//              Navigator.pop(context);
//            }),
//        title: new Text(patientCode.split("-")[0]),
//        automaticallyImplyLeading: false,
//        actions: <Widget>[
//          new IconButton(
//              icon: new Icon(Icons.share),
//              onPressed: () {
//                shareButton();
//              })
//        ],
//      ),
//      body: new Column(
//        children: <Widget>[
//          new Flexible(
//            child: new FirebaseAnimatedList(
//              query: referenceToEMR,
//              itemBuilder: (_, DataSnapshot snapshot,
//                  Animation<double> animation, int i) {
//                return textRenderForEMR(snapshot);
//              },
////              sort: (a, b) => b.key.compareTo(a.key),
//              defaultChild: new Center(child: new Text("Loading...")),
//            ),
//          ),
//        ],
//      ),
//    );
//  }
//
//  //share button email
//  Future shareButton() async {
//    List shareData;
//    String shareDataText = "Medical Records of $patientCode : \n\n";
//    await FirebaseDatabase.instance
//        .reference()
//        .child("DeXAutoCollect")
//        .child("EMR")
//        .child(_emailID.replaceAll(".", " "))
//        .child(patientCode)
//        .once()
//        .then((DataSnapshot snap) {
//      shareData = snap.value;
//    });
//    for (var i = 0; i < shareData.length - 1; i++) {
//      print("==============>${shareData[i]["head"]}");
//      String shareDataTextloopHead;
//      String shareDataTextloopCon;
//
//      shareDataTextloopHead = shareData[i]["head"].toString();
//      shareDataTextloopCon = shareData[i]["con"].toString();
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
//  Widget textRenderForEMR(snapshot) {
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
//  }
//}
