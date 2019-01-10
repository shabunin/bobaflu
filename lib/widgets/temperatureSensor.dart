import 'package:flutter/material.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccTemperatureSensor extends StatefulWidget {
  // DONE: pass bobaos
  // DONE: state when update happened. info variable is a pointer to accessoryList[index]

  AccTemperatureSensor({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccTemperatureSensor createState() => _AccTemperatureSensor();
}

class _AccTemperatureSensor extends State<AccTemperatureSensor> {
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
          trailing: new Text("${info.currentState['current']}"),
          onTap: () {
            // send read request on tap
            setState(() {
              bobaos.controlAccessoryValue(info.id, {"read": true},
                  (bool err, Object payload) {
                if (err) {
                  return print('error ocurred $payload');
                }

                print(payload);
              });
            });
          },
          onLongPress: () {
            // TODO: dialog with additional funcs
          },
        ));
  }
}
