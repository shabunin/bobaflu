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
    // here is list tile for accessory list
    dynamic cardColor = Theme.of(context).cardColor;
    dynamic playing = info.currentState['playing'];
    dynamic stationId = info.currentState['station'];
    List<dynamic> radioList = info.currentState['radio list'];
    dynamic stationTitle = "";
    // different card color depending on state
    if (playing is bool) {
      if (playing) {
        cardColor = Colors.amber;
        // find station in list
        dynamic stationItemIndex = radioList.indexWhere((t) => t['id'] == stationId);
        if (stationItemIndex > -1) {
          stationTitle = radioList[stationItemIndex]['name'];
        }
      } else {
        cardColor = Theme.of(context).cardColor;
        stationTitle = "not playing";
      }
    }
    return Card(
        color: cardColor,
        child: ListTile(
          leading: Icon(Icons.radio),
          title: Text(info.name),
          subtitle: Text(stationTitle),
          onTap: () {
            setState(() {
              // so, on tap it receives current playing state at first
              bobaos.getStatusValue(info.id, "playing", (bool err, Object payload) {
                if (err) {
                  return print('error ocurred $payload');
                }

                print(payload);
                if (payload is Map) {
                  dynamic currentValue = payload['status']['value'];
                  bool newValue;
                  if (currentValue is bool) {
                    // invert value
                    newValue = !currentValue;
                  } else {
                    newValue = false;
                  }
                  // and send new value to bobaoskit.worker
                  bobaos.controlAccessoryValue(info.id, {"playing": newValue}, (bool err, Object payload) {
                    if (err) {
                      return print('error ocurred $payload');
                    }

                    print(payload);
                  });
                }
              });
            });
          },
          // on long press open page with radio list
          onLongPress: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AccRadioPlayerControl(
                      info: info,
                      bobaos: bobaos,
                    )));
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
    AccessoryInfo info = widget.info;
    BobaosWs bobaos = widget.bobaos;
    return new Scaffold(
        appBar: AppBar(
          title: Text(info.name),
        ),
        body: ScopedModel<AccessoryInfo>(
            model: info,
            child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
              List<dynamic> radioList = model.currentState['radio list'];
              return ListView.builder(
                  itemCount: radioList.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    return new RadioListTile(
                        title: Text(radioList[index]['name']),
                        value: radioList[index]['id'],
                        groupValue: model.currentState['station'],
                        onChanged: (v) {
                          print(v);
                          // on change radio value it send command to switch station
                          bobaos.controlAccessoryValue(model.id, {"station": v}, (bool err, Object payload) {
                            if (err) {
                              return print('error ocurred $payload');
                            }
                          });
                        });
                  });
            })));
  }
}
