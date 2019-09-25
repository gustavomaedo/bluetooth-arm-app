import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GamePad extends StatelessWidget {

  const GamePad(
      {
        Key key,
        this.a,
        this.w,
        this.s,
        this.d,
        this.t,
        this.f,
        this.g,
        this.h,
        this.btnType = true,
        this.setType,
        this.btw,
        this.bta,
        this.btf,
        this.btt
      }) :
        super(key: key);

  final Function w;
  final Function a;
  final Function s;
  final Function d;
  final Function t;
  final Function f;
  final Function g;
  final Function h;
  final Function setType;
  final Function(LongPressMoveUpdateDetails) btw;
  final Function(LongPressMoveUpdateDetails) bta;
  final Function(LongPressMoveUpdateDetails) btf;
  final Function(LongPressMoveUpdateDetails) btt;

  final bool btnType;

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: btnType ? joystick() : gyroscope(),
    );
  }

  Container joystick() {
    return new Container(
        alignment: Alignment.bottomCenter,
        child: Column(
          children: <Widget>[
            swit(),
            new Padding(padding: const EdgeInsets.all(10.0)),
            flats(f,h, true),
            new Padding(padding: const EdgeInsets.all(10.0)),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Padding(padding: const EdgeInsets.all(10.0)),
                buttons(a,d, Colors.blueGrey),
                buttons(t,g, Colors.blueGrey),
                new Padding(padding: const EdgeInsets.all(10.0)),
              ],
            ),
            new Padding(padding: const EdgeInsets.all(10.0)),
            flats(w,s, false),
            new Padding(padding: const EdgeInsets.all(30.0)),
          ],
        )
    );
  }

  Container gyroscope() {
    return new Container(
        alignment: Alignment.bottomCenter,
        child: Column(
          children: <Widget>[
            swit(),
            new Padding(padding: const EdgeInsets.all(10.0)),
            hold(btt, color: Colors.green, icon: Icons.close),
            new Padding(padding: const EdgeInsets.all(10.0)),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Padding(padding: const EdgeInsets.all(10.0)),
                hold(bta, color: Colors.blueGrey),
                hold(btf, color: Colors.blueGrey),
                new Padding(padding: const EdgeInsets.all(10.0)),
              ],
            ),
            new Padding(padding: const EdgeInsets.all(10.0)),
            hold(btw, width: 180, icon: Icons.code),
            new Padding(padding: const EdgeInsets.all(30.0)),
          ],
        )
    );
  }

  GestureDetector hold(Function a, {double width, Color color, IconData icon}) {
    return new GestureDetector(
      onLongPressMoveUpdate: a,
      child: Material(
        elevation: 8.0,
        color: color ?? Colors.blue,
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
        child: Container(
          width: width ?? 50,
          height: 50,
          child: Icon(icon ?? Icons.keyboard_arrow_up, color: Colors.white),
        ),
      ),
    );
  }


  GestureDetector swit() {
    return new GestureDetector(
      onTap: setType,
      child: Material(
        elevation: 8.0,
        color: Colors.red,
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
        child: Container(
          width: 50,
          height: 50,
          child: Icon(Icons.sync, color: Colors.white),
        ),
      ),
    );
  }

  Column buttons(Function a, Function b, Color color) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new FloatingActionButton(
          child: new Icon(Icons.keyboard_arrow_up),
          mini: true,
          onPressed: a,
          heroTag: null,
          backgroundColor: color ?? Colors.grey[700],
          foregroundColor: Colors.white,
        ),
        new Padding(padding: const EdgeInsets.all(5.0)),
        new FloatingActionButton(
          child: new Icon(Icons.keyboard_arrow_down),
          mini: true,
          onPressed: b,
          heroTag: null,
          backgroundColor: color ?? Colors.grey[700],
          foregroundColor: Colors.white,
        )
      ],
    );
  }

  Row flats(Function a, Function b, bool open) {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        new Padding(padding: const EdgeInsets.all(10.0)),
        new RaisedButton(
          child: new Icon(open ? Icons.remove: Icons.keyboard_arrow_left),
          onPressed: a,
          color: open ? Colors.white : Colors.blue,
          textColor: open ? Colors.red : Colors.white,
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
          elevation: 8.0,
        ),
        new RaisedButton(
          child: new Icon(open ? Icons.add: Icons.keyboard_arrow_right),
          onPressed: b,
          color: open ? Colors.white : Colors.blue,
          textColor: open ? Colors.green : Colors.white,
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
          elevation: 8.0,
        ),
        new Padding(padding: const EdgeInsets.all(10.0)),
      ],
    );
  }

}
