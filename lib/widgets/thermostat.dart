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
    dynamic currentMode = info.currentState['mode'];
    switch (currentMode) {
      case "off":
        cardColor = Colors.grey;
        break;
      case "heat":
        cardColor = Colors.amber;
        break;
      case "cool":
        cardColor = Colors.lightBlue;
        break;
      case "auto":
        cardColor = Colors.green;
        break;
      default:
        break;
    }

    return Card(
        color: cardColor,
        child: ListTile(
          selected: false,
          leading: new Icon(Icons.ac_unit),
          title: new Text("${info.name}"),
          subtitle: new Text(
              "${info.currentState['current temperature']} >> ${info.currentState['setpoint']}"),
          trailing: new CircleAvatar(child: new Text("${currentMode[0]}")),
          onTap: () {
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
    AccessoryInfo info = widget.info;
    BobaosWs bobaos = widget.bobaos;
    void changeSetpointBy(double value) {
      bobaos.getStatusValue(info.id, "setpoint", (bool err, Object payload) {
        if (err) {
          return print('error ocurred $payload');
        }

        print(payload);
        if (payload is Map) {
          dynamic currentValue = payload['status']['value'];
          dynamic newValue = currentValue + value;
          bobaos.controlAccessoryValue(info.id, {"setpoint": newValue},
              (bool err, Object payload) {
            if (err) {
              return print('error ocurred $payload');
            }

            print(payload);
          });
        }
      });
    }

    return new Scaffold(
        appBar: AppBar(
          title: Text(info.name),
        ),
        body: ScopedModel<AccessoryInfo>(
            model: info,
            child: ListView(
              children: <Widget>[
                ScopedModelDescendant<AccessoryInfo>(
                    builder: (context, child, model) {
                  var cardColor;
                  dynamic currentMode = model.currentState['mode'];
                  switch (currentMode) {
                    case "off":
                      cardColor = Colors.grey;
                      break;
                    case "heat":
                      cardColor = Colors.amber;
                      break;
                    case "cool":
                      cardColor = Colors.lightBlue;
                      break;
                    case "auto":
                      cardColor = Colors.green;
                      break;
                    default:
                      break;
                  }
                  return Column(children: <Widget>[
                    SizedBox(
                        height: 64,
                        child: Card(
                            color: cardColor,
                            child: Center(
                                child: Text(
                                    "Temperature now: ${model.currentState['current temperature']}",
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700))))),

                    // setpoint
                    SizedBox(
                        height: 120,
                        child: Card(
                            color: cardColor,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: SizedBox(
                                      height: 120,
                                      child: InkWell(
                                        child: Icon(Icons.remove_circle),
                                        onTap: () {
                                          changeSetpointBy(-1);
                                        },
                                      )),
                                ),
                                Column(
                                  children: <Widget>[
                                    Text("Setpoint:",
                                        style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900)),
                                    Expanded(
                                      child: Center(
                                          child: Text(
                                              "${model.currentState['setpoint']}",
                                              style: TextStyle(
                                                  fontSize: 42,
                                                  fontWeight:
                                                      FontWeight.w900))),
                                    )
                                  ],
                                ),
                                Expanded(
                                  child: SizedBox(
                                      height: 120,
                                      child: InkWell(
                                        child: Icon(Icons.add_circle),
                                        onTap: () {
                                          changeSetpointBy(1);
                                        },
                                      )),
                                )
                              ],
                            ))),
                  ]);
                }),

                // modes
                ScopedModelDescendant<AccessoryInfo>(
                    builder: (context, child, model) {
                  dynamic currentMode = model.currentState['mode'];
                  List<dynamic> modes = model.currentState['modes available'];
                  return SizedBox(
                      height: 48,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: modes.length,
                          itemBuilder: (BuildContext ctx, int index) {
                            return Row(children: <Widget>[
                              Radio(
                                value: modes[index],
                                groupValue: currentMode,
                                onChanged: (dynamic value) {
                                  bobaos.controlAccessoryValue(
                                      info.id, {"mode": value},
                                      (bool err, Object payload) {
                                    if (err) {
                                      return print('error ocurred $payload');
                                    }

                                    print(payload);
                                  });
                                },
                              ),
                              Text("${modes[index]}")
                            ]);
                          }));
                }),

                // sensors
                ScopedModelDescendant<AccessoryInfo>(
                    builder: (context, child, model) {
                  return Row(
                    children: <Widget>[
                      Expanded(
                          child: Text(
                              "Temperature: ${model.currentState['sensors']['temperature']}")),
                      Expanded(
                          child: Text(
                              "Humidity: ${model.currentState['sensors']['humidity']}")),
                      Expanded(
                          child: Text(
                              "CO2: ${model.currentState['sensors']['co2']}")),
                    ],
                  );
                }),

                // error state
                ScopedModelDescendant<AccessoryInfo>(
                    builder: (context, child, model) {
                  var errorState = model.currentState['error state']['error'];
                  if (errorState is bool) {
                    if (errorState) {
                      return Card(
                          color: Colors.red,
                          child: Text(
                            "${model.currentState['error state']['message']}",
                            style: TextStyle(
                                fontSize: 42, fontWeight: FontWeight.w900),
                          ));
                    }
                  }

                  return new Container();
                }),
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
