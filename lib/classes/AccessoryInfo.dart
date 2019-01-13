import 'package:scoped_model/scoped_model.dart';

// AccessoryInfo extends Model
// so, when accessory value is updated it descends down to
// all widgets inside ScopedModelDescendant
class AccessoryInfo extends Model {
  dynamic id;
  dynamic type;
  String name;
  String job_channel;
  List control;
  List status;
  bool selected;
  Map<dynamic, dynamic> currentState;

  AccessoryInfo(Map<dynamic, dynamic> obj) {
    this.id = obj['id'];
    this.type = obj['type'];
    this.name = obj['name'];
    this.job_channel = obj['job_channel'];
    this.control = obj['control'];
    this.status = obj['status'];
    this.currentState = {};
  }

  void updateCurrentState(key, value) {
    currentState[key] = value;
    notifyListeners();
  }
}
