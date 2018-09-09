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

  @override
  void initState() {
//    loadingInsights();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
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
              color: Colors.grey[50],
              elevation: 1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0,10.0,30.0,10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0,0.0,25.0,0.0),
                      child: new CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 13.0,
                        animation: true,
                        percent: percentSVT.floor()/100,
                        center: new Text(
                          percentSVT.toStringAsPrecision(3)+'%',
                          style:
                          new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                        footer: new Text(
                          '% Transcribed',
                          style:
                          new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.purple,
                      ),
                    ),
                    Column(
                      children: <Widget>[

                        Text(
                          'Total Records:',
                          style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.blueGrey[300],
                              fontWeight: FontWeight.normal),
                        ),
                        Text(
                          savedRecords.toString(),
                          style: TextStyle(
                              fontSize: 50.0,
                              color: Colors.blueGrey[600],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Transcribed:',
                          style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.blueGrey[300],
                              fontWeight: FontWeight.normal),
                        ),
                        Text(
                          savedNTransRecords.toString(),
                          style: TextStyle(
                              fontSize: 50.0,
                              color: Colors.blueGrey[600],
                              fontWeight: FontWeight.bold),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.grey[50],
              elevation: 1.0,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text('Minutes Captured: ',
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.blueGrey[300],
                          fontWeight: FontWeight.normal),
                    ),
                    Text(minutesCap.toString(),
                      style: TextStyle(
                          fontSize: 34.0,
                          color: Colors.blueGrey[600],
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
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
