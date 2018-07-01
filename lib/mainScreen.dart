import 'package:flutter/material.dart';
import 'package:dex_for_doctor/recorderWidget.dart';
import 'package:dex_for_doctor/emrListWidget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key key, this.email});

  final String email;

  @override
  _MainScreenState createState() => new _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    String _emailID = widget.email;

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("DeX EMR"),
        elevation: 4.0,
        backgroundColor: Colors.teal[800],
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: new Column(
        children: <Widget>[
          new RecorderWidget(),
          Expanded(
            child: new EMRListWidget(email: _emailID),
          ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text("Go"),
            Transform.rotate(
              child: new Icon(Icons.subdirectory_arrow_left),
              angle: 0.0,
            ),
          ],
        ),
      ),
    );
  }
}
