import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_search/material_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dex_for_doctor/emrWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

class SearchF extends StatefulWidget {
  const SearchF({Key key, this.email});
  final String email;
  @override
  _SearchFState createState() => _SearchFState();
}

class _SearchFState extends State<SearchF> {
  //STATE FOR DATA LOADING

  int searchDataLoadScreenState = 0;

  String email;

  int whetherSearchedState = 0;

  TextEditingController tname = new TextEditingController();
  TextEditingController tsname = new TextEditingController();
  TextEditingController tph = new TextEditingController();

  List<String> _names = [];
  List<String> _phone = [];

  List<Widget> listArray = [];

  List dattt = [];
//  List<String> patientCode = [];

  @override
  void initState() {
    //load data in string
//    loadingSearchDataFunction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text('Search For Patient'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            print(">>Navigator.pop");
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.teal[800],
      ),
      body: searchBody(),
    );
  }

  Widget searchBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        searchBodySearchBox(),
        searchBodyResults(),
      ],
    );
  }

  Widget searchBodySearchBox() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Type all or anyone of the Individual blanks:\n(Internet connection is Required)',
            style: TextStyle(color: Colors.teal),
          ),
          Divider(),
//          TextField(
//            decoration: InputDecoration(
//              hintText: 'First Name Or',
//              contentPadding: const EdgeInsets.all(5.0),
//              border: InputBorder.none,
//              prefixIcon: Icon(Icons.edit,color: Colors.grey,),
//            ),
//            controller: tname,
//          ),
          Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Last Name Or',
                      contentPadding: const EdgeInsets.all(5.0),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.edit,
                        color: Colors.grey,
                      ),
                    ),
                    controller: tsname,
                  ),
                ),
                new RawMaterialButton(
                  onPressed: () {
                    print(">>Clicked On Search");
                    whetherSearchedState = 1;
                    searchBodySearchBoxFunc();
                  },
                  child: new Icon(
                    Icons.forward,
                    size: 22.0,
                    color: Colors.teal,
                  ),
                  shape: new CircleBorder(),
                  elevation: 1.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(10.0),
                ),
              ],
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: '10 Digit Phone',
              contentPadding: const EdgeInsets.all(5.0),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.edit,
                color: Colors.grey,
              ),
            ),
            controller: tph,
            keyboardType: TextInputType.numberWithOptions(),
          ),
        ],
      ),
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.all(10.0),
    );
  }

  //LOAD THE SEARCH
  Future searchBodySearchBoxFunc() async {
    dattt.clear();
    String usid;
    await auth.currentUser().then((user) {
      usid = user.uid;
      print("usid>> ${user.uid}");
    });
    //query for phone
    await Firestore.instance
        .collection('ptsP')
        .where('usid', isEqualTo: usid)
        .where('ph', isEqualTo: tph.text)
        .getDocuments()
        .then((docum) {
      for (int j = 0; j < docum.documents.length; j++) {
        print('>>docu..data: ${docum.documents[j].data}');
        dattt.add(docum.documents[j].data);
      }
      print(">dattt: $dattt");
    });
    //last name
    await Firestore.instance
        .collection('ptsP')
        .where('usid', isEqualTo: usid)
        .where('ns', isEqualTo: tsname.text)
        .getDocuments()
        .then((docum) {
      for (int j = 0; j < docum.documents.length; j++) {
        print('>>docu..data: ${docum.documents[j].data}');
        dattt.add(docum.documents[j].data);
      }
      print(">dattt: $dattt");
    });

    setState(() {
      whetherSearchedState = 1;
    });

    FocusScope.of(context).requestFocus(new FocusNode());
  }

  Widget searchBodyResults() {
    if (whetherSearchedState == 1) {
      if (dattt.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 80.0, left: 20.0),
          child: Text('No Patients Found..\nPlease Retry Or Contact Support'),
        );
      } else {
        createListArray();
        return Column(
          children: <Widget>[
            ListView(shrinkWrap: true, children: listArray),
          ],
        );
      }
    } else {
      return Container();
    }
  }

  createListArray(){
    for (int j = 0; j < dattt.length; j++) {
      listArray.add(
        Column(
          children: <Widget>[
            new ListTile(
              title: new Text(
                dattt[j]['nn']+' '+dattt[j]['ns'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.search),
              onTap: (){
                Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
                  return new EMRPage(
                    name: dattt[j]['nn'],
                    sname: dattt[j]['ns'],
                    phnumber: dattt[j]['ph'],
                    usid: dattt[j]['usid'],
                  );
                }));
              },
              trailing: Icon(Icons.arrow_forward),
            ),
            Divider()
          ],
        ),
      );
    }
  }

  //OLD CODE WITH MATERIAL SEARCH
/*  @override
  Widget build(BuildContext context) {
    if (searchDataLoadScreenState == 0) {
      return loadingDataWidget();
    } else {
      return new Material(
        child: new MaterialSearch<String>(
          placeholder: 'Search Patient',
          results: patientCode
              .map((String v) => new MaterialSearchResult<String>(
                    icon: Icons.subdirectory_arrow_right,
                    value: v,
                    text: "$v",
                  ))
              .toList(),
          filter: (dynamic value, String criteria) {
            return value
                .toLowerCase()
                .trim()
                .contains(new RegExp(r'' + criteria.toLowerCase().trim() + ''));
          },
          onSelect:
              (dynamic value) =>
//              MATERIAL ROUTE TO EMR
              Navigator
                  .of(context)
                  .push(new MaterialPageRoute(builder: (context) {
                return new EMRPage(
//                  email: widget.email,
//                  patientCode: value,
                );
              })),
        ),
      );
    }
  }

  //THIS SHOWS LOADING SCREEN AND MSSG
  Widget loadingDataWidget() {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("DeX Search loading..."),
        backgroundColor: Colors.teal[800],
      ),
      body: Center(
        child: new Text("Loading...\nInternet connection is required"),
      ),
    );
  }

  //GETTING THE NEW NAMES
  loadingSearchDataFunction() async {
    await FirebaseDatabase.instance
        .reference()
        .child("DeXAutoCollect")
        .child("list")
        .child(widget.email.replaceAll(".", " "))
        .orderByChild("conversionStatus")
        .equalTo(1)
        .once()
        .then((DataSnapshot ds) {
      Map dataW = ds.value;
//      List<String> dataWS = [];
      dataW.keys.forEach((k) => _names.add(dataW[k]["newName"]));
      dataW.keys.forEach((k) => _phone.add(dataW[k]["phone"].toString()));

      for (int l = 0; l < _names.length; l++) {
        patientCode.add(_names[l] + "-" + _phone[l]);
        print(_names[l] + _phone[l]);
      }

//      dataWS.removeWhere((String s) => s == null);
//      print("SF-loaded data: ${dataWS}");
//      _names = _names + dataWS;
      print("SF-loaded data: $patientCode");
    });
    searchDataLoadScreenState = 1;
    setState(() {});
  }*/
}
