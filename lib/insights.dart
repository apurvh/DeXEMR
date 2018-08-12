import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

class InsightsData extends StatefulWidget {
  @override
  _InsightsDataState createState() => _InsightsDataState();
}

class _InsightsDataState extends State<InsightsData> {


  String savedRecords = '00';
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
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40.0,10.0,40.0,10.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          savedRecords,
                          style: TextStyle(
                              fontSize: 50.0,
                              color: Colors.blueGrey[600],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Saved Records',
                          style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.blueGrey[300],
                              fontWeight: FontWeight.normal),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
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
      savedRecords=data.documents[0]['nre'].toString();
      print('>>nre FETCHED: $savedRecords');
      setState(() {
        setStateOnceogic=1;
      });
    });

  }
}
