import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccRadioPlayer extends StatefulWidget {
  // DONE: pass bobaos
  // DONE: state when update happened. info variable is a pointer to accessoryList[index]

  AccRadioPlayer({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccRadioPlayer createState() => _AccRadioPlayer();
}

class _AccRadioPlayer extends State<AccRadioPlayer> {
  AccessoryInfo info;
  BobaosWs bobaos;

  @override
  void initState() {
    super.initState();
    info = widget.info;
    bobaos = widget.bobaos;
  }

  @override
  Widget build(BuildContext context) {
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ListTile(
          selected: false,
          leading: new Icon(Icons.radio),
          title: new Text(
              "${info.name}: ${info.currentState['playing'].toString()}"),
          trailing: new Switch(
              activeColor: Colors.redAccent,
              activeTrackColor: Colors.teal,
              value: info.currentState['playing'] is bool
                  ? info.currentState['playing']
                  : false,
              onChanged: null),
          onTap: () {
            setState(() {
              bobaos.getStatusValue(info.id, "playing",
                  (bool err, Object payload) {
                if (err) {
                  return print('error ocurred $payload');
                }

                print(payload);
                if (payload is Map) {
                  dynamic currentValue = payload['status']['value'];
                  bool newValue;
                  if (currentValue is bool) {
                    newValue = !currentValue;
                  } else {
                    newValue = false;
                  }
                  bobaos.controlAccessoryValue(info.id, {"playing": newValue},
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
          onLongPress: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AccRadioPlayerControl(
                      info: info,
                      bobaos: bobaos,
                    )));
            // DONE: dialog with radio list
//            showDialog(
//                context: context,
//                builder: (BuildContext ctx) {
//                  List<dynamic> radioList = info.currentState['radio list'];
//                  dynamic _current = info.currentState['station'];
//                  print(radioList);
//                  return Dialog(
//                      child: ListView.builder(
//                          itemCount: radioList.length,
//                          itemBuilder: (BuildContext ctx, int index) {
//                            return new RadioListTile(
//                                title: Text(radioList[index]['name']),
//                                value: radioList[index]['id'],
//                                groupValue: _current,
//                                onChanged: (v) {
//                                  print(v);
//                                  bobaos.controlAccessoryValue(
//                                      info.id, {"station": v},
//                                      (bool err, Object payload) {
//                                    if (err) {
//                                      return print('error ocurred $payload');
//                                    }
//
//                                    _current = v;
//                                  });
//                                });
//                          }));
//                });
//            });
          },
        ));
  }
}

class AccRadioPlayerControl extends StatefulWidget {
  AccRadioPlayerControl({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccRadioPlayerControl createState() => _AccRadioPlayerControl();
}

class _AccRadioPlayerControl extends State<AccRadioPlayerControl> {
  @override
  Widget build(BuildContext context) {
    List<dynamic> radioList = widget.info.currentState['radio list'];
    dynamic _current = widget.info.currentState['station'];
    return new Scaffold(
        appBar: AppBar(
          title: Text(widget.info.name),
        ),
        body: ScopedModel<AccessoryInfo>(
            model: widget.info,
            child: ListView.builder(
                itemCount: radioList.length,
                itemBuilder: (BuildContext ctx, int index) {
                  return new ScopedModelDescendant<AccessoryInfo>(
                      builder: (context, child, model) {
                    return new RadioListTile(
                        title: Text(
                            model.currentState['radio list'][index]['name']),
                        value: model.currentState['radio list'][index]['id'],
                        groupValue: model.currentState['station'],
                        onChanged: (v) {
                          print(v);
                          widget.bobaos
                              .controlAccessoryValue(model.id, {"station": v},
                                  (bool err, Object payload) {
                            if (err) {
                              return print('error ocurred $payload');
                            }

                            _current = v;
                          });
                        });
                  });
                })));

//    return new ScopedModel<AccessoryInfo>(
//      model: widget.info,
//      child: new ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
//
//      }, child: new )
//    );
  }
}
