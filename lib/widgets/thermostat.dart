import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../BobaosKit.dart';

class AccThermostat extends StatelessWidget {
  AccThermostat({Key key, this.info, this.bobaos}) : super(key: key);

  AccessoryInfo info;
  BobaosKitWs bobaos;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          var cardColor = Theme.of(context).cardColor;
          dynamic currentMode = model.currentState['mode'];
          // ok
          // now card color depends on working mode
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
                title: new Text("${model.name}"),
                subtitle: new Text("${model.currentState['current temperature']} >> ${model.currentState['setpoint']}"),
                trailing: new CircleAvatar(child: new Text("${currentMode[0]}")),
                onTap: () {
                  // on tap open control page
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AccThermostatControl(
                            info: info,
                            bobaos: bobaos,
                          )));
                },
              ));
        }));
  }
}

class AccThermostatControl extends StatelessWidget {
  AccThermostatControl({Key key, this.info, this.bobaos}) : super(key: key);

  final AccessoryInfo info;
  final BobaosKitWs bobaos;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          var cardColor;
          dynamic currentMode = model.currentState['mode'];
          List<dynamic> modes = model.currentState['modes available'];
          List<dynamic> messages = model.currentState['status messages'];

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

          void changeSetpointBy(double value) {
            bobaos.getStatusValue(model.id, "setpoint", (bool err, Object payload) {
              if (err) {
                return print('error ocurred $payload');
              }

              print(payload);
              if (payload is Map) {
                dynamic currentValue = payload['status']['value'];
                dynamic newValue = currentValue + value;
                bobaos.controlAccessoryValue(model.id, {"setpoint": newValue}, (bool err, Object payload) {
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
                title: Text(model.name),
              ),
              // list of cards
              body: ListView(
                children: <Widget>[
                  // current temp and setpoint
                  Column(children: <Widget>[
                    SizedBox(
                        height: 64,
                        child: Card(
                            color: cardColor,
                            child: Center(
                                child: Text("Temperature now: ${model.currentState['current temperature']}",
                                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))))),

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
                                    Text("Setpoint:", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                                    Expanded(
                                      child: Center(
                                          child: Text("${model.currentState['setpoint']}",
                                              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900))),
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
                  ]),

                  // modes
                  SizedBox(
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
                                  bobaos.controlAccessoryValue(info.id, {"mode": value}, (bool err, Object payload) {
                                    if (err) {
                                      return print('error ocurred $payload');
                                    }

                                    print(payload);
                                  });
                                },
                              ),
                              Text("${modes[index]}")
                            ]);
                          })),

                  // sensors
                  Row(
                    children: <Widget>[
                      Expanded(child: Text("Temperature: ${model.currentState['sensors']['temperature']}")),
                      Expanded(child: Text("Humidity: ${model.currentState['sensors']['humidity']}")),
                      Expanded(child: Text("CO2: ${model.currentState['sensors']['co2']}")),
                    ],
                  ),

                  // error state
                  // as an example I made switching to heat mode giving error
                  ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
                    var errorState = model.currentState['error state']['error'];
                    if (errorState is bool) {
                      if (errorState) {
                        return Card(
                            color: Colors.red,
                            child: Text(
                              "${model.currentState['error state']['message']}",
                              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
                            ));
                      }
                    }

                    return new Container();
                  }),

                  // status messages
                  // other messages can be used to describe current state of device, like fancoils are on, etc
                  SizedBox(
                      height: 142,
                      child: Card(
                          color: Colors.teal,
                          child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: messages.length,
                              itemBuilder: (BuildContext ctx, int index) {
                                return Text("${messages[index]}");
                              }))),
                ],
              ));
        }));
  }
}
