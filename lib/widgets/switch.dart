import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccSwitch extends StatelessWidget {
  AccSwitch({
    Key key,
    this.info,
    this.bobaos,
  }) : super(key: key);

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  Widget build(BuildContext context) {
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          var cardColor = Theme.of(context).cardColor;
          dynamic switchState = model.currentState['state'];
          if (switchState is bool) {
            if (switchState) {
              cardColor = Colors.deepPurple;
            } else {
              cardColor = Theme.of(context).cardColor;
            }
          }
          return Card(
              color: cardColor,
              child: ListTile(
                selected: false,
                leading: new Icon(Icons.lightbulb_outline),
                title: new Text("${model.name}"),
                //                trailing: new Switch(value: switchState is bool ? switchState : false, onChanged: (bool state) {
                //                }),
                onTap: () {
                  // get status value at first
                  bobaos.getStatusValue(model.id, "state", (bool err, Object payload) {
                    if (err) {
                      return print('error ocurred $payload');
                    }

                    if (payload is Map) {
                      dynamic currentValue = payload['status']['value'];
                      bool newValue;
                      if (currentValue is bool) {
                        // invert
                        newValue = !currentValue;
                      } else {
                        newValue = false;
                      }
                      // then send new value
                      bobaos.controlAccessoryValue(model.id, {"state": newValue}, (bool err, Object payload) {
                        if (err) {
                          return print('error ocurred $payload');
                        }
                      });
                    }
                  });
                },
                onLongPress: () {
                  // TODO: dialog with additional funcs
                },
              ));
        }));
  }
}
