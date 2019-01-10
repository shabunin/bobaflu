import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccThermostat extends StatefulWidget {
  // DONE: pass bobaos
  // DONE: state when update happened. info variable is a pointer to accessoryList[index]

  AccThermostat({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccThermostat createState() => _AccThermostat();
}

class _AccThermostat extends State<AccThermostat> {
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
    var cardColor = Theme.of(context).cardColor;

    return Card(
        color: cardColor,
        child: ListTile(
          selected: false,
          leading: new Icon(Icons.ac_unit),
          title: new Text("${info.name}"),
          subtitle: new Text(
              "${info.currentState['current temperature']} >> ${info.currentState['setpoint']}"),
          // TODO: mode icon/color
          trailing:
              new CircleAvatar(child: new Text("${info.currentState['mode']}")),
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
                        decoration: new InputDecoration(hintText: "100"),
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
                            bobaos
                                .controlAccessoryValue(info.id, {"power": true},
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
          onLongPress: () {
            // TODO:  with additional funcs
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AccThermostatControl(
                      info: info,
                      bobaos: bobaos,
                    )));
          },
        ));
  }
}

class AccThermostatControl extends StatefulWidget {
  AccThermostatControl({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccThermostatControl createState() => _AccThermostatControl();
}

class _AccThermostatControl extends State<AccThermostatControl> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text(widget.info.name),
        ),
        body: ScopedModel<AccessoryInfo>(
            model: widget.info,
            child: ListView(
              children: <Widget>[
                // setpoint
                new Card(
                    color: Colors.amber,
                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          child: Icon(Icons.remove_circle),
                          onTap: () {},
                        ),
                        Text("22.0"),
                        GestureDetector(
                          child: Icon(Icons.add_circle),
                          onTap: () {},
                        )
                      ],
                    ))
              ],
            )));
  }
}

//    return new ScopedModel<AccessoryInfo>(
//      model: widget.info,
//      child: new ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
//
//      }, child: new )
//    );
