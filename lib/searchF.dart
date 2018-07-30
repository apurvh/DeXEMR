import 'package:flutter/material.dart';
import 'package:material_search/material_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dex_for_doctor/emrWidget.dart';

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

  List<String> _names = [];
  List<String> _phone = [];
  List<String> patientCode = [];

  @override
  void initState() {
    //load data in string
    loadingSearchDataFunction();
    super.initState();
  }

  @override
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
  }
}
