import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../classes/AccessoryInfo.dart';
import '../BobaosKit.dart';

class AccTemperatureSensor extends StatelessWidget {
  AccTemperatureSensor({Key key, this.info, this.bobaos}) : super(key: key);

  final AccessoryInfo info;
  final BobaosKitWs bobaos;

  @override
  Widget build(BuildContext context) {
    return new ScopedModel<AccessoryInfo>(
        model: info,
        child: ScopedModelDescendant<AccessoryInfo>(builder: (context, child, model) {
          var cardColor = Theme.of(context).cardColor;
          return Card(
              color: cardColor,
              child: ListTile(
                selected: false,
                leading: new Icon(Icons.ac_unit),
                title: new Text("${model.name}"),
                trailing: new Text("${model.currentState['current']}"),
                onTap: () {
                  // send read request on tap
                  bobaos.controlAccessoryValue(model.id, {"read": true}, (bool err, Object payload) {
                    if (err) {
                      return print('error ocurred $payload');
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
