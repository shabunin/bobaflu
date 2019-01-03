import 'package:flutter/material.dart';
import 'package:mdns/mdns.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import './classes/AccessoryInfo.dart';

import './bobaos.dart';
import './widgets/switch.dart';
import './widgets/radioPlayer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bobaflu',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(title: 'bobaflu'),
    );
  }
}

const String discovery_service = "_bobaoskit._tcp";

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class BobaosFound {
  String name;
  String host;
  int port;

  BobaosFound(String name, String host, int port) {
    this.name = name;
    this.host = host;
    this.port = port;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  DiscoveryCallbacks discoveryCallbacks;
  List<BobaosFound> litems = [];

  TextEditingController _c;

  @override
  initState() {
    super.initState();

    _c = new TextEditingController();

    discoveryCallbacks = new DiscoveryCallbacks(onDiscoveryStarted: () {
      print("Discovery started");
    }, onDiscoveryStopped: () {
      print("Discovery stopped");
    }, onDiscovered: (ServiceInfo info) {
      print("Discovered ${info.toString()}");
    }, onResolved: (ServiceInfo info) {
      print("Resolved Service ${info.toString()}");
      setState(() {
        BobaosFound bobaosFoundItem =
            new BobaosFound(info.name, info.host, info.port);
        litems.add(bobaosFoundItem);
      });
    }, onLost: (ServiceInfo info) {
      print("Lost Service ${info.toString()}");
      int index =
          litems.indexWhere((BobaosFound item) => item.name == info.name);
      setState(() {
        litems.removeAt(index);
      });
    });

    startMdnsDiscovery(discovery_service);
  }

  startMdnsDiscovery(String serviceType) {
    Mdns mdns = new Mdns(discoveryCallbacks: discoveryCallbacks);
    mdns.startDiscovery(serviceType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: new FloatingActionButton(
        // When the user presses the button, show an alert dialog with the
        // text the user has typed into our text field.
        onPressed: () {
          return showDialog(
            context: context,
            builder: (context) {
              return new Dialog(
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new TextField(
                      decoration:
                          new InputDecoration(hintText: "10.0.42.33:49190"),
                      controller: _c,
                    ),
                    new FlatButton(
                      child: new Text("Connect"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccessoryListPage(
                                  title: "/${_c.text}", host: "/${_c.text}")),
                        );
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
        tooltip: 'Manual input',
        child: Icon(Icons.settings),
      ),
      body: ListView.builder(
        itemCount: litems.length,
        itemBuilder: (BuildContext ctx, int index) {
          return new ListTile(
              selected: false,
              leading: new CircleAvatar(
                child: new Text(litems[index].name[0]),
              ),
              title: new Text(litems[index].name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AccessoryListPage(
                          title:
                              "${litems[index].host}:${litems[index].port.toString()}",
                          host:
                              "${litems[index].host}:${litems[index].port.toString()}")),
                );
              });
        },
      ),
    );
  }
}

class AccessoryListPage extends StatefulWidget {
  AccessoryListPage({Key key, this.title, this.host}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String host;

  @override
  _AccessoryListPage createState() => _AccessoryListPage();
}

class _AccessoryListPage extends State<AccessoryListPage> {
  List<AccessoryInfo> accessoryList = [];
  BobaosWs bobaos;

  initState() {
    super.initState();
    print("hello, friend, ${widget.host}");
    initBobaos();
  }

  initBobaos() async {
    bobaos = new BobaosWs("ws:/${widget.host}");
    bobaos.removeAllListeners();
    bobaos.registerListener("update status value", (dynamic payload) {
      print("update status value event");
      print(payload);
      dynamic id = payload['id'];
      // find accessory in list and update state
      int index = accessoryList.indexWhere((f) => f.id == id);
      if (index > -1) {
        print("inde > -1: $index}");
        AccessoryInfo info = accessoryList[index];
        print(info);
        dynamic statusValues = payload['status'];
        if (statusValues is Map) {
          dynamic field = statusValues['field'];
          dynamic value = statusValues['value'];
          accessoryList[index].currentState[field] = value;
        }
        if (statusValues is List) {
          statusValues.forEach((statusValue) {
            if (statusValue is Map) {
              dynamic field = statusValue['field'];
              dynamic value = statusValue['value'];
              accessoryList[index].currentState[field] = value;
            }
          });
        }
        setState(() {});
      }
    });

    await bobaos.initWs();
    bobaos.getAccessoryInfo(null, (bool err, Object payload) {
      if (err) {
        return print('error ocurred $payload');
      }

      print(payload);
      List<Object> tmpList = payload;
      setState(() {
        tmpList.forEach((t) {
          AccessoryInfo f = new AccessoryInfo(t);
          bobaos.getStatusValue(f.id, f.status, (bool err, dynamic payload) {
            dynamic statusValues = payload['status'];
            print("get all statuses!!");
            print(statusValues.toString());
            if (statusValues is Map) {
              dynamic field = statusValues['field'];
              dynamic value = statusValues['value'];
              f.currentState[field] = value;
            }
            if (statusValues is List) {
              statusValues.forEach((statusValue) {
                if (statusValue is Map) {
                  dynamic field = statusValue['field'];
                  dynamic value = statusValue['value'];
                  f.currentState[field] = value;
                }
              });
            }
            setState(() {
              accessoryList.add(f);
            });
          });
        });
        // get status values for each accessory
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async {
          await bobaos.closeWs();
          Navigator.of(context).pop();
        },
        child: new Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            leading: new IconButton(
              icon: new Icon(Icons.arrow_back),
              onPressed: () async {
                await bobaos.closeWs();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: ListView.builder(
            itemCount: accessoryList.length,
            itemBuilder: (BuildContext ctx, int index) {
              AccessoryInfo info = accessoryList[index];
              if (info.type == "switch") {
                return AccSwitch(
                  info: info,
                  bobaos: bobaos,
                );
              }
              if (info.type == "temperature sensor") {
                return ListTile(
                  leading: Icon(Icons.ac_unit),
                  title: Text(
                      "${info.name}: ${info.currentState['current'].toString()}"),
                  onTap: () {
                    // read value on tap
                    bobaos.controlAccessoryValue(info.id, {"read": true},
                        (bool err, Object payload) {
                      if (err) {
                        return print('error ocurred $payload');
                      }

                      print(payload);
                    });
                  },
                );
              }
              if (info.type == "thermostat basic") {
                return ListTile(
                  leading: Icon(Icons.beach_access),
                  title: Text(
                      "${info.name}: ${info.currentState['current'].toString()} ==> ${info.currentState['setpoint']}"),
                  onTap: () {
                    TextEditingController _c = new TextEditingController();

                    // TODO: open page
                    return showDialog(
                      context: context,
                      builder: (context) {
                        return new Dialog(
                          child: new Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new TextField(
                                decoration:
                                    new InputDecoration(hintText: "100"),
                                controller: _c,
                              ),
                              new FlatButton(
                                child: new Text("Set"),
                                onPressed: () {
                                  int setpoint = int.parse(_c.text);
                                  bobaos.controlAccessoryValue(
                                      info.id, {"setpoint": setpoint},
                                      (bool err, Object payload) {
                                    if (err) {
                                      return print('error ocurred $payload');
                                    }

                                    print(payload);
                                    Navigator.pop(context);
                                    bobaos.controlAccessoryValue(
                                        info.id, {"power": true},
                                        (bool err, Object payload) {
                                      if (err) {
                                        return print('error ocurred $payload');
                                      }

                                      print(payload);
                                    });
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
              if (info.type == "radio player") {
                return AccRadioPlayer(info: info, bobaos: bobaos);
              }
            },
          ),
        ));
  }
}
