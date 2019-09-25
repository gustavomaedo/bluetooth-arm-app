import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sensors/sensors.dart';
import 'ConnectBluetooth.dart';
import 'GamePad.dart';

class RobotController extends StatefulWidget {
  @override
  RobotControllerState createState() => new RobotControllerState();
}

class RobotControllerState extends State<RobotController> {
  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;

  bool btnType = true;

  bool connected = false;
  BluetoothConnection connection;

  StreamSubscription<AccelerometerEvent> _accelerometer;
  StreamSubscription<GyroscopeEvent> _gyroscope;

  AccelerometerEvent acc;
  GyroscopeEvent gyr;

  String receiverData = "";
  bool notHold = true;

  bool get isConnected => connection != null && connection.isConnected;

  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    cancelGyro();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void initGyro() {
    _accelerometer = accelerometerEvents.listen((AccelerometerEvent event) {
      if(this.mounted) {
        setState(() {
          acc = event;
        });
      }
    });

    _gyroscope = gyroscopeEvents.listen((GyroscopeEvent event) {
      if(this.mounted) {
        setState(() {
          gyr = event;
        });
      }
    });
  }

  void cancelGyro() {
    if(_gyroscope != null) {
      _gyroscope.cancel();
    }
    if(_accelerometer != null) {
      _accelerometer.cancel();
    }
  }


  void _navConnect() async {
    BluetoothConnection _connection = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ConnectBluetooth(connected: connected, connection: connection)));
    if(_connection != null) {
      initGyro();
      setState(() {
        connected = true;
        connection = _connection;
      });
      listenToDevice();
    }
  }

  void listenToDevice() async {

    connection.input.listen(_onDataReceived).onDone(() {
      print('Disconnected by remote request');
      cancelGyro();
      if(this.mounted) {
        setState(() {
          connected = false;
          connection.dispose();
          connection = null;
        });
      }
    });
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      }
      else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        }
        else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) { // \r\n
      setState(() {
        receiverData = dataString.substring(index);
      });
      print(dataString);
      print(data);
      print(receiverData);
    }
  }

  Widget cardsLayout({String text, Function onTap,
    Color color, Color textColor, double width, double height
  }) {
    if(text == null) {
      text = '';
    }
    return new InkWell(
      onTap: onTap ?? () => {},
      child: new Card(
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
        margin: EdgeInsets.all(20.0),
        elevation: 8.0,
        color: color ?? null,
        child: Container(
            width: width ?? 210,
            height: height ?? null,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('$text',
                    textScaleFactor: 1.0,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor
                    ),
                  )
                ],
              ),
            )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: new PreferredSize(
        child: new AppBar(
        centerTitle: false,
            title: (
                Text('Controle do Robô')
            )
        ),
            preferredSize: Size.fromHeight(48.0)),
        body: SafeArea(
            child: !connected ? Center(
                child: cardsLayout(
                    text: 'CONECTAR\nCOM ROBÔ',
                    onTap: () => _navConnect(),
                    color: Colors.blue,
                    textColor: Colors.white,
                  height: 180,
                  width: 180
                ),)
                : isConnected ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                btnType ? Container() : Container(
                  padding: EdgeInsets.only(top: 50),
                  child: gyr != null && acc != null
                      ? Text("Gyroscópio:\nX: ${gyr.x.ceilToDouble()}, Y: ${gyr.y.ceilToDouble()}, Z: ${gyr.z.ceilToDouble()}\n\n"
                      "Acelerômetro\nX: ${acc.x.ceilToDouble()}, Y: ${acc.y.ceilToDouble()}, Z: ${acc.z.ceilToDouble()}")
                  : Text("No data"),
                ),
                GamePad(
                  w: () => _sendData('w'),
                  s: () => _sendData('s'),
                  a: () => _sendData('a'),
                  d: () => _sendData('d'),
                  f: () => _sendData('f'),
                  h: () => _sendData('h'),
                  t: () => _sendData('t'),
                  g: () => _sendData('g'),
                  btnType: btnType,
                  setType: setType,
                  btw: (a) => _sendHold(0),
                  bta: (a) => _sendHold(1),
                  btf: (a) => _sendHold(2),
                  btt: (a) => _sendHold(3),
                )
              ],
            ) : Center(child: CircularProgressIndicator())
        )
    );
  }

  void _sendData(String text) {
    text = text.trim();
    if (text.length > 0 && connection != null)  {
      print(text);
      connection.output.add(utf8.encode(text + "\r\n"));

    }
  }

  void _sendHold(int typeS) {
    String text;
    double accY = acc.y.ceilToDouble();
    double accX = acc.x.ceilToDouble();
    if(typeS == 0) {
      if(accX > 1) {
        text = "w";
      } else if(accX < -1) {
        text = "s";
      }
    } else if(typeS == 1) {
      if(accY > 1) {
        text = "a";
      } else if(accY < -1) {
        text = "d";
      }
    } else if(typeS == 2) {
      if(accY > 1) {
        text = "g";
      } else if(accY < -1) {
        text = "t";
      }
    } else if(typeS == 3) {
      if(accX > 1) {
        text = "f";
      } else if(accX < -1) {
        text = "h";
      }
    }

    if(notHold && text != null) {
      if(this.mounted){
        setState(() {
          notHold = false;
        });
      }
      Timer(const Duration(milliseconds: 600), () {
        if(this.mounted){
          setState(() {
            notHold = true;
          });
        }
      });
    text = text.trim();
    if (text.length > 0 && connection != null) {
      print(text);
      connection.output.add(utf8.encode(text + "\r\n"));
    }

    }
  }

  void setType() {
    if(this.mounted) {
      setState(() {
        btnType = !btnType;
      });
    }
  }

}

