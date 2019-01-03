import 'package:flutter/material.dart';

import '../classes/AccessoryInfo.dart';
import '../bobaos.dart';

// TODO: listile
// TODO: onTap => play/pause
// TODO: onLongTap => showDialog radio list

class AccRadioPlayer extends StatefulWidget {
  // TODO: pass bobaos
  // TODO: state when update happened
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
    // TODO: implement initState
    super.initState();
    info = widget.info;
    bobaos = widget.bobaos;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListTile(
      title: Text(info.name),
      onTap: () {
        bobaos.getStatusValue(info.id, "playing", (err, res) {
          print(res);
        });
      },
    );
  }
}

//  showDialog(
//      context: context,
//      builder: (BuildContext ctx){
//
//        return Dialog(
//            child: Container(
//                child:Column(
//                  children:<Widget>[
//                    new RadioListTile( value: sortBy.asc,groupValue: _selected,onChanged: (v){
//                      print(_selected);
//
//                      _selected = v;
//                    },
//                    ),
//                    new RadioListTile( value: sortBy.desc,groupValue: _selected,onChanged: (v){
//                      print(_selected);
//                      _selected = v;
//                    },
//                    ),
//                  ],
//                )
//            )
//        );
//      }
//  );
