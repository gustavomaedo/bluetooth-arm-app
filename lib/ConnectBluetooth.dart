/*
    * AUTHOR     GUSTAVO MAEDO
    * COPYRIGHT  2019 HM
    *
    * CREATE USER PROFILE SCREEN
    */

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConnectBluetooth extends StatefulWidget {

  final connected;
  final connection;

  ConnectBluetooth({Key key,
    @required this.connected,
    @required this.connection
  }) : super (key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new ConnectBluetoothState();
  }
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}



class ConnectBluetoothState extends State<ConnectBluetooth>   with TickerProviderStateMixin {

  String robotName = "HC-05";
  AnimationController _controller;
  AnimationController _blueControl;
  Animation<double> _animation;
  Animation<double> _blue;

  BluetoothConnection connection;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool _autoAcceptPairingRequests = false;

  bool connected = false;
  bool bounded = false;

  // Availability
  StreamSubscription<BluetoothDiscoveryResult> _discoveryStreamSubscription;
  bool _isDiscovering;

  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;

  bool noConnection = false;

  bool notFound = false;

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;


  @override
  void initState() {
    super.initState();

    _blueControl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..addListener(() => setState(() {}));
    _blue = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(_blueControl);


    _blue.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blueControl.repeat(reverse: true);
      }
    });

    _controller = AnimationController(
        duration: const Duration(seconds: 1), vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {

        }
      });

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
        connected = widget.connected;
        bounded = widget.connected;
      });
      if(state.isEnabled && !connected) {
        _blueControl.forward();
        boundedDevice();
      }
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field

    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      if(this.mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }
    });

    _controller.forward();

  }

  void boundedDevice() async {

    await FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices) {
          BluetoothDevice device;
          for (BluetoothDevice d in bondedDevices){
                  if (d.name == robotName) {
                    device = d;
                  }
                }
          if(device != null) {
            setState(() {
              bounded = true;
            });
            _controller.forward();
            connectToDevice(device);
          } else {
            _restartDiscovery();
          }
    });

  }

  void _restartDiscovery() {
    setState(() {
      _isDiscovering = true;
      notFound = false;
      connected = false;
      bounded = false;
    });
    _controller.forward();
    _blueControl.forward();
    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          if (r.device.name == robotName) {
            boundToDevice(r);
            _discoveryStreamSubscription.cancel();
          }
    });

    _discoveryStreamSubscription.onDone(() {
      setState(() {
        _isDiscovering = false;
        notFound = true;
      });
      _blueControl.stop();
    });
  }

  void boundToDevice(BluetoothDiscoveryResult result) async {
    setState(() {
      print('Bounded');
      bounded = true;
    });
    try {
      bool bonded = false;
      if (result.device.isBonded) {
        print('Unbonding from ${result.device.address}...');
        await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(result.device.address);
        print('Unbonding from ${result.device.address} has succed');
      }
      else {
        print('Bonding with ${result.device.address}...');
        bonded = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(result.device.address);
        print('Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
        connectToDevice(result.device);
      }
      _controller.forward();
    }
    catch (ex) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while bonding'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    await BluetoothConnection.toAddress(device.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        connected = true;
        isConnecting = false;
      });
      Navigator.of(context).pop(_connection);
    }).catchError((e){
      if(this.mounted) {
        setState(() {
          noConnection = true;
          notFound = true;
        });
      }
    });
    _blueControl.stop();
  }

  @override
  void dispose() {
    if(_controller != null) {
      _controller.dispose();
    }
    if(_blueControl != null) {
      _blueControl.dispose();
    }
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  void disconnect() {
    String text = "P".trim();
    if (text.length > 0 && widget.connection != null)  {
      print(text);
      widget.connection.output.add(utf8.encode(text + "\r\n"));
      Navigator.of(context).pop();
    }
  }

  Future enableBluetooth() async {
    if(!_bluetoothState.isEnabled) {
      await FlutterBluetoothSerial.instance.requestEnable();
      _controller.forward();
      _blueControl.forward();
      boundedDevice();
    }
  }

  Widget turnBluetooth() {
    return new GestureDetector(
      onTap: enableBluetooth,
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Padding(padding: new EdgeInsets.all(70.0)),
          new Container(
              height: 100,
              child: blueIcon(off: true)
          ),
          new Padding(padding: new EdgeInsets.all(10.0)),
          new Center(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 40.0),
              child: new Text('Ativar Bluetooth',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: new TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget blueIcon({bool off = false}) {
    return new Card(
      margin: EdgeInsets.symmetric(horizontal: _blue.value * 12.0),
      elevation: _blue.value * 10.0,
      color: off ? Colors.grey[600] : Colors.blue[400],
      shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(_blue.value * 50.0)),
      child: Container(
        width: _blue.value * 100.0,
        height: _blue.value * 100.0,
        child: Container(
              padding: EdgeInsets.all(_blue.value * 9.0),
              child: Card(
                  color: Colors.white,
                  elevation: _blue.value * 15.0,
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(_blue.value * 50.0)),
                  child: new Icon(Icons.bluetooth, size: _blue.value * 50, color: off ? Colors.grey[600] : Colors.blue),
                  ),
        ),
      ),
    );
  }

  Widget connectedIcon() {
    return new Card(
          margin: EdgeInsets.symmetric(horizontal: 12.0),
          elevation: 10.0,
          color: Colors.green[400],
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(50.0)),
          child: Container(
            width: 100.0,
            height: 100.0,
            child: Container(
              padding: EdgeInsets.all(9.0),
              child: Card(
                color: Colors.white,
                elevation: 15.0,
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(50.0)),
                child: new Icon(Icons.bluetooth_connected, size: 50, color: Colors.green),
              ),
            ),
          ),
        );
  }

  Widget findBluetooth() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(70.0)),
        new Container(
            height: 100,
            child: blueIcon()
        ),
        new Padding(padding: new EdgeInsets.all(10.0)),
        new Center(
          child: new Container(
            margin: new EdgeInsets.symmetric(horizontal: 40.0),
            child: new Text('Procurando...',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget noBluetooth() {
    return new GestureDetector(
      onTap: boundedDevice,
      child: new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(70.0)),
        new Container(
            height: 100,
            child: blueIcon(off: true)
        ),
        new Padding(padding: new EdgeInsets.all(10.0)),
        new Center(
          child: new Container(
            margin: new EdgeInsets.symmetric(horizontal: 40.0),
            child: new Text('Não encotrado\nTentar novamente',
              maxLines: 2,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget connectingBlue() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(70.0)),
        new Container(
            height: 100,
            child: blueIcon()
        ),
        new Padding(padding: new EdgeInsets.all(10.0)),
        new Center(
          child: new Container(
            margin: new EdgeInsets.symmetric(horizontal: 40.0),
            child: new Text('Connectando...',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget connectedBlue() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Padding(padding: new EdgeInsets.all(70.0)),
        new Container(
            height: 100,
            child: connectedIcon()
        ),
        new Padding(padding: new EdgeInsets.all(10.0)),
        new Center(
          child: new Container(
            margin: new EdgeInsets.symmetric(horizontal: 40.0),
            child: new Text('Connectado',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
          ),
        ),
        new Padding(padding: new EdgeInsets.all(20.0)),
        new FlatButton(
            onPressed: disconnect,
            child: new Text("Desconectar",
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: new TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red
              ),
            ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget child) {
          // TODO: implement build
          return new Scaffold(
            appBar: new PreferredSize(child: new AppBar(
              centerTitle: true,
              title: new Text("Bluetooth")
            ),
                preferredSize: Size.fromHeight(48.0)),
            body: new Container(
              decoration: BoxDecoration(
                // Box decoration takes a gradient
                gradient: LinearGradient(
                  // Where the linear gradient begins and ends
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  // Add one stop for each color. Stops should increase from 0 to 1
                  stops: [_animation.value + 0.75, _animation.value + 1.0],
                  colors: [
                    // Colors are easy thanks to Flutter's Colors class.
                    Colors.grey[900],
                    _bluetoothState.isEnabled && !notFound ? connected ? Colors.green : Colors.blue : Colors.grey,
                  ],
                ),
              ),
              child: _bluetoothState.isEnabled ?
                  notFound ? noBluetooth() :
              bounded ? connected ?
                   connectedBlue()
                  : connectingBlue()
                  : findBluetooth()
                  : turnBluetooth()
            ),
          );
        }
    );
  }
}
