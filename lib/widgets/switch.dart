import 'package:flutter/material.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccSwitch extends StatefulWidget {
  // DONE: pass bobaos
  // DONE: state when update happened. info variable is a pointer to accessoryList[index]

  AccSwitch({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccSwitch createState() => _AccSwitch();
}

class _AccSwitch extends State<AccSwitch> {
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
    dynamic switchState = info.currentState['state'];
    if (switchState is bool) {
      if (switchState) {
        cardColor = Colors.deepPurple;
      } else {
        cardColor = Theme.of(context).cardColor;
      }
    }
    return new Card(
        color: cardColor,
        child: ListTile(
          selected: false,
          leading: new Icon(Icons.lightbulb_outline),
          title: new Text(
              "${info.name}"),
          trailing: new Switch(
              value: switchState is bool
                  ? switchState
                  : false,
              onChanged: (bool state) {}),
          onTap: () {
            setState(() {
              bobaos.getStatusValue(info.id, "state",
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
                  bobaos.controlAccessoryValue(info.id, {"state": newValue},
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
            // TODO: dialog with additional funcs
          },
        ));
  }
}
