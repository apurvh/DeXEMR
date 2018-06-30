import 'package:flutter/material.dart';

class RecorderWidget extends StatefulWidget {
  @override
  _RecorderWidgetState createState() => _RecorderWidgetState();
}

class _RecorderWidgetState extends State<RecorderWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.fromLTRB(12.0, 25.0, 12.0, 25.0),
      color: Colors.blueGrey[50],
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new Column(
            children: <Widget>[
              new RawMaterialButton(
                onPressed: () {},
                child: new Icon(
                  Icons.pause,
                  size: 40.0,
                  color: Colors.blueGrey[800],
                ),
                shape: new CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(15.0),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: new Text(
                  "Pause",
                  style: new TextStyle(
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          new Container(
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[50],
              border: Border.all(
                color: Colors.red[300],
                width: 10.0,
              ),
              boxShadow: [
                new BoxShadow(
                  blurRadius: 1.0,
                  spreadRadius: 0.0,
                  color: Colors.red[800],
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Text(
                    "00:02",
                    style: new TextStyle(
                      fontSize: 25.0,
                      color: Colors.grey[900],
//                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  new Text(
                    "Timer",
                    style: new TextStyle(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          new Column(
            children: <Widget>[
              new RawMaterialButton(
                onPressed: () {},
                child: new Icon(
                  Icons.done,
                  size: 40.0,
                  color: Colors.teal[600],
                ),
                shape: new CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(15.0),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: new Text(
                  "Save",
                  style: new TextStyle(
                    color: Colors.teal[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
