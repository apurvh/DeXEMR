import 'package:flutter/material.dart';
import 'package:dex_for_doctor/recorderWidget.dart';
import 'package:dex_for_doctor/emrListWidget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dex_for_doctor/emrListWidget.dart';

import 'package:scoped_model/scoped_model.dart';

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

    return new ScopedModel<CounterModel>(
      model: new CounterModel(),
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text("DeX EMR"),
          elevation: 3.0,
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
            new ScopedModelDescendant<CounterModel>(
              builder: (context, child, model) =>
                  renderRecordWidget(model.counter),
            ),
            Expanded(
              child: new EMRListWidget(email: _emailID),
            ),
          ],
        ),
        floatingActionButton: new ScopedModelDescendant<CounterModel>(
          builder: (context, child, model) => renderFloatingActionButton(model),
        ),
      ),
    );
  }

  Widget renderRecordWidget(int recorderWidgetState) {
    if (recorderWidgetState.isEven) {
      return Container();
    } else {
      return new RecorderWidget(
        email: widget.email,
      );
    }
  }

  Widget renderFloatingActionButton(model) {
    if (model.counter.isOdd) {
      return Container();
    } else {
      return new FloatingActionButton(
        onPressed: () {
          model.increment();
          print("====>>>>  ${model.counter}");
        },
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
      );
    }
  }
}

class CounterModel extends Model {
  int _counter = 0;

  int get counter => _counter;

  void increment() {
    // First, increment the counter
    _counter++;

    // Then notify all the listeners.
    notifyListeners();
  }

  void decrement() {
    // First, increment the counter
    _counter--;

    // Then notify all the listeners.
    notifyListeners();
  }
}
