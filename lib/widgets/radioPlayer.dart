import 'package:flutter/material.dart';

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
    return ListTile(
      selected: false,
      leading: new Icon(Icons.radio),
      title:
          new Text("${info.name}: ${info.currentState['playing'].toString()}"),
      trailing: new Switch(
          activeColor: Colors.redAccent,
          activeTrackColor: Colors.teal,
          value: info.currentState['playing'] is bool
              ? info.currentState['playing']
              : false,
          onChanged: null),
      onTap: () {
        setState(() {
          bobaos.getStatusValue(info.id, "playing", (bool err, Object payload) {
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
        // DONE: dialog with radio list
        showDialog(
            context: context,
            builder: (BuildContext ctx) {
              List<dynamic> radioList = info.currentState['radio list'];
              dynamic _current = info.currentState['station'];
              print(radioList);
              return Dialog(
                  child: ListView.builder(
                      itemCount: radioList.length,
                      itemBuilder: (BuildContext ctx, int index) {
                        return new RadioListTile(
                            title: Text(radioList[index]['name']),
                            value: radioList[index]['id'],
                            groupValue: _current,
                            onChanged: (v) {
                              print(v);
                              bobaos.controlAccessoryValue(
                                  info.id, {"station": v},
                                  (bool err, Object payload) {
                                if (err) {
                                  return print('error ocurred $payload');
                                }

                                _current = v;
                              });
                            });
                      }));
            });
      },
    );
  }
}
