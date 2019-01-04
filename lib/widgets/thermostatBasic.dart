import 'package:flutter/material.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

class AccThermostatBasic extends StatefulWidget {
  // DONE: pass bobaos
  // DONE: state when update happened. info variable is a pointer to accessoryList[index]

  AccThermostatBasic({Key key, this.info, this.bobaos}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final AccessoryInfo info;
  final BobaosWs bobaos;

  @override
  _AccThermostatBasic createState() => _AccThermostatBasic();
}

class _AccThermostatBasic extends State<AccThermostatBasic> {
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
      leading: new Icon(Icons.ac_unit),
      title: new Text("${info.name}"),
      trailing: new Text("${info.currentState['current']} >> ${info.currentState['setpoint']}"),
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
                        bobaos.controlAccessoryValue(info.id, {"power": true},
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
      },
    );
  }
}
