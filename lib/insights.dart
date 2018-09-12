import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

import 'package:percent_indicator/percent_indicator.dart';


class InsightsData extends StatefulWidget {

//  const InsightsData({Key key,this.usid});

  @override
  _InsightsDataState createState() => _InsightsDataState();
}

class _InsightsDataState extends State<InsightsData> {


  int savedRecords = 0;
  int savedNTransRecords = 0;

  int minutesCap = 0;

  double percentSVT=0.0;

  MediaQueryData queryData;

  @override
  void initState() {

//    loadingInsights();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {

    queryData=MediaQuery.of(context);
    print('....queryData.textScaleFactor ${queryData.textScaleFactor}');
    double textScale = queryData.textScaleFactor;

    loadingInsights();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('  I N S I G H T S',style: TextStyle(fontWeight: FontWeight.bold),),
                IconButton(icon: Icon(Icons.close), onPressed: () {
                  Navigator.pop(context);
                })
              ],
            ),
            Divider(),
            Card(
              color: Colors.white,
              elevation: 1.0,
              child: Row(
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(25.0,15.0,25.0,10.0),
                      child: new CircularPercentIndicator(
                        backgroundColor: Colors.grey[100],
                        fillColor: Colors.white,
                        radius: 80.0,
                        lineWidth: 10.0,
                        animation: true,
                        percent: percentSVT.floor()/100,
                        center: new Text(
                          percentSVT.toStringAsPrecision(3)+'%',
                          style:
                          new TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.purple,
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.stop,color: Colors.blueGrey[100],),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Icon(Icons.stop,color: Colors.purple,),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0.0,8.0,18.0,3.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Total Records:',
                                style: TextStyle(
                                    fontSize: 14.0/textScale,
                                    color: Colors.blueGrey[400],
                                    fontWeight: FontWeight.normal),
                              ),
                              Text(savedRecords.toString(),
                                style: TextStyle(
                                    fontSize: 20.0/textScale,
                                    color: Colors.blueGrey[600],
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0.0,3.0,18.0,8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Transcribed:',
                                style: TextStyle(
                                    fontSize: 14.0/textScale,
                                    color: Colors.blueGrey[400],
                                    fontWeight: FontWeight.normal),
                              ),
                              Text(savedNTransRecords.toString(),
                                style: TextStyle(
                                    fontSize: 20.0/textScale,
                                    color: Colors.blueGrey[600],
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 1.0,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0,18.0,18.0,3.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Time Captured(Mins): ',
                          style: TextStyle(
                              fontSize: 14.0/textScale,
                              color: Colors.blueGrey[400],
                              fontWeight: FontWeight.normal),
                        ),
                        Text(minutesCap.toString(),
                          style: TextStyle(
                              fontSize: 30.0/textScale,
                              color: Colors.blueGrey[600],
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0,3.0,18.0,8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Average time/patient(Mins): ',
                          style: TextStyle(
                              fontSize: 14.0/textScale,
                              color: Colors.blueGrey[400],
                              fontWeight: FontWeight.normal),
                        ),
                        Text((minutesCap/savedNTransRecords).toStringAsPrecision(3),
                          style: TextStyle(
                              fontSize: 30.0/textScale,
                              color: Colors.blueGrey[600],
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  int setStateOnceogic=0;
  loadingInsights()async{
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("usid>> ${user.uid}");
    });
    if(setStateOnceogic==0)
    Firestore.instance.collection('docsP').where('usid',isEqualTo: usid).getDocuments().then((data){
      savedRecords=data.documents[0]['nre'];
      savedNTransRecords=data.documents[0]['nrt'];
      minutesCap=data.documents[0]['nrm'];

      percentSVT=savedNTransRecords/savedRecords;
      percentSVT=percentSVT*100;

      print('>>nre FETCHED: $savedRecords');
      setState(() {
        setStateOnceogic=1;
      });
    });

  }
}
