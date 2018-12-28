import 'package:flutter/material.dart';
import 'package:mdns/mdns.dart';

// from dartpg
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

class BobaosCallback {
  String name;
  Function cb;

  BobaosCallback(String name, Function cb) {
    this.name = name;
    this.cb = cb;
  }
}

class BobaosWs {
  String url;
  WebSocket ws;

  int _req_count;
  Map _reqs;

  // callbacks for bcasted events
  List<BobaosCallback> _events;

  void registerListener(String name, Function cb) {
    this._events.add(new BobaosCallback(name, cb));
  }

  void removeAllListeners() {
    this._events = [];
  }

  void emitEvent(String name, dynamic params) {
    // call all listeners
    List<BobaosCallback> foundCallbacks =
        this._events.where((t) => t.name == name).toList();
    foundCallbacks.forEach((f) => f.cb(params));
  }

  void initWs() async {
    try {
      this.ws = await WebSocket.connect(this.url);
      print("readyState: ${this.ws.readyState}");
      this.listen();
    } catch (e) {
      print(e);
    }
  }

  void closeWs() async {
    try {
      print("closin websocket");
      this.removeAllListeners();
      await this.ws.close(1, "done");
    } catch (e) {
      print(e);
    }
  }

  void listen() {
    this.ws.listen((text) {
      var json = jsonDecode(text);
      if (json.containsKey('response_id')) {
        var response_id = json['response_id'];
        if (this._reqs.containsKey(response_id)) {
          var cb = this._reqs[response_id];
          if (json['method'] == 'success') {
            cb(false, json['payload']);
          } else {
            cb(true, json['payload']);
          }
          this._reqs.remove(response_id);
          //print('after removing ${this._reqs}');
        }
      } else {
        // broadcasted event
        this.emitEvent(json['method'], json['payload']);
      }
    });
  }

  void getGeneralInfo(Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get general info";
    obj2send["payload"] = null;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void getAccessoryInfo(dynamic id, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get accessory info";
    obj2send["payload"] = id;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void getStatusValue(dynamic id, dynamic status, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get status value";

    var payload = {};
    payload["id"] = id;
    List<Object> statusList = [];
    if (status is List) {
      status.forEach((e) {
        statusList.add(e);
      });
      payload['status'] = statusList;
    } else {
      payload['status'] = status;
    }
    obj2send["payload"] = payload;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void controlAccessoryValue(
      dynamic id, Map<dynamic, dynamic> value, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "control accessory value";

    List<Object> valueList = [];
    value.forEach((k, v) {
      valueList.add({'field': k, 'value': v});
    });
    var payload = {};
    payload["id"] = id;
    if (valueList.length == 1) {
      payload["control"] = valueList[0];
    } else {
      payload["control"] = valueList;
    }
    obj2send["payload"] = payload;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  BobaosWs(String url) {
    this.url = url;
    this._reqs = new Map<int, Function>();
    this._req_count = 0;
    this._events = new List<BobaosCallback>();
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

class AccessoryInfo {
  dynamic id;
  dynamic type;
  String name;
  String job_channel;
  List control;
  List status;
  bool selected;
  Map<dynamic, dynamic> currentState;

  AccessoryInfo(Map<dynamic, dynamic> obj) {
    this.id = obj['id'];
    this.type = obj['type'];
    this.name = obj['name'];
    this.job_channel = obj['job_channel'];
    this.control = obj['control'];
    this.status = obj['status'];
    this.currentState = {};
  }
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
    new Timer(const Duration(seconds: 0), () {
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
                return SwitchListTile(
                  title: new Text(info.name),
                  value: (info.currentState['state'] is bool)
                      ? info.currentState['state']
                      : false,
                  onChanged: (bool value) {
                    setState(() {
                      bobaos.getStatusValue(info.id, "state",
                          (bool err, Object payload) {
                        if (err) {
                          return print('error ocurred $payload');
                        }

                        print(payload);
                        if (payload is Map) {
                          print("this is map. good");
                          dynamic currentValue = payload['status']['value'];
                          bool newValue;
                          if (currentValue is bool) {
                            newValue = !currentValue;
                          } else {
                            newValue = false;
                          }
                          bobaos.controlAccessoryValue(
                              info.id, {"state": newValue},
                              (bool err, Object payload) {
                            if (err) {
                              return print('error ocurred $payload');
                            }

                            print(payload);
                          });
                        }
                      });
                    });
                  },
                  secondary: const Icon(Icons.lightbulb_outline),
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
            },
          ),
        ));
  }
}
