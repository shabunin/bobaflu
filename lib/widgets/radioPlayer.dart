import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

// To use as a template for accessories
//class AccRadioPlayerLess extends StatelessWidget {
//  AccRadioPlayerLess({Key key, this.info, this.bobaos}) : super(key: key);
//
//  AccessoryInfo info;
//  BobaosWs bobaos;
//
//  @override
//  Widget build(BuildContext context) {
//    // TODO: implement build
//    return new ScopedModel<AccessoryInfo>(
//        model: info,
//        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
//
//        }));
//  }
//}

class AccRadioPlayer extends StatelessWidget {
  AccRadioPlayer({Key key, this.info, this.bobaos}) : super(key: key);

  AccessoryInfo info;
  BobaosWs bobaos;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          // here is list tile for accessory list
          dynamic cardColor = Theme.of(context).cardColor;
          dynamic playing = model.currentState['playing'];
          dynamic stationId = model.currentState['station'];
          List<dynamic> radioList = model.currentState['radio list'];
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
                title: Text(model.name),
                subtitle: Text(stationTitle),
                onTap: () {
                  // so, on tap it receives current playing state at first
                  bobaos.getStatusValue(model.id, "playing", (bool err, Object payload) {
                    if (err) {
                      return print('error ocurred $payload');
                    }

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
                      bobaos.controlAccessoryValue(model.id, {"playing": newValue}, (bool err, Object payload) {
                        if (err) {
                          return print('error ocurred $payload');
                        }
                      });
                    }
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
        }));
  }
}

class AccRadioPlayerControl extends StatelessWidget {
  AccRadioPlayerControl({Key key, this.info, this.bobaos}) : super(key: key);

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  Widget build(BuildContext context) {
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          return new Scaffold(
              appBar: AppBar(
                title: Text(model.name),
              ),
              body: ScopedModel<AccessoryInfo>(
                  model: model,
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
                                // on change radio value it send command to switch station
                                bobaos.controlAccessoryValue(model.id, {"station": v}, (bool err, Object payload) {
                                  if (err) {
                                    return print('error ocurred $payload');
                                  }
                                });
                              });
                        });
                  })));
        }));
  }
}
