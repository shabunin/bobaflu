import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BobaosCallback {
  String name;
  Function cb;

  BobaosCallback(String name, Function cb) {
    this.name = name;
    this.cb = cb;
  }
}

class BobaosWs {
  String url;
  WebSocket ws;

  int _req_count;
  Map _reqs;

  // callbacks for bcasted events
  List<BobaosCallback> _events;

  void registerListener(String name, Function cb) {
    this._events.add(new BobaosCallback(name, cb));
  }

  void removeAllListeners() {
    this._events = [];
  }

  void emitEvent(String name, dynamic params) {
    // call all listeners
    List<BobaosCallback> foundCallbacks =
    this._events.where((t) => t.name == name).toList();
    foundCallbacks.forEach((f) => f.cb(params));
  }

  void initWs() async {
    try {
      this.ws = await WebSocket.connect(this.url);
      print("readyState: ${this.ws.readyState}");
      this.listen();
    } catch (e) {
      print(e);
    }
  }

  void closeWs() async {
    try {
      print("closin websocket");
      this.removeAllListeners();
      await this.ws.close(1, "done");
    } catch (e) {
      print(e);
    }
  }

  void listen() {
    this.ws.listen((text) {
      var json = jsonDecode(text);
      if (json.containsKey('response_id')) {
        var response_id = json['response_id'];
        if (this._reqs.containsKey(response_id)) {
          var cb = this._reqs[response_id];
          if (json['method'] == 'success') {
            cb(false, json['payload']);
          } else {
            cb(true, json['payload']);
          }
          this._reqs.remove(response_id);
          //print('after removing ${this._reqs}');
        }
      } else {
        // broadcasted event
        this.emitEvent(json['method'], json['payload']);
      }
    });
  }

  void getGeneralInfo(Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get general info";
    obj2send["payload"] = null;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void getAccessoryInfo(dynamic id, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get accessory info";
    obj2send["payload"] = id;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void getStatusValue(dynamic id, dynamic status, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "get status value";

    var payload = {};
    payload["id"] = id;
    List<Object> statusList = [];
    if (status is List) {
      status.forEach((e) {
        statusList.add(e);
      });
      payload['status'] = statusList;
    } else {
      payload['status'] = status;
    }
    obj2send["payload"] = payload;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  void controlAccessoryValue(
      dynamic id, Map<dynamic, dynamic> value, Function cb) async {
    print("readyState: ${this.ws.readyState}");
    if (this.ws.readyState == 0) {
      await this.initWs();
    }
    this._req_count += 1;
    int request_id = this._req_count;
    var obj2send = {};
    obj2send["request_id"] = request_id;
    obj2send["method"] = "control accessory value";

    List<Object> valueList = [];
    value.forEach((k, v) {
      valueList.add({'field': k, 'value': v});
    });
    var payload = {};
    payload["id"] = id;
    if (valueList.length == 1) {
      payload["control"] = valueList[0];
    } else {
      payload["control"] = valueList;
    }
    obj2send["payload"] = payload;
    print('sending ${jsonEncode(obj2send)}');
    this.ws.add(jsonEncode(obj2send));
    this._reqs[request_id] = cb;
  }

  BobaosWs(String url) {
    this.url = url;
    this._reqs = new Map<int, Function>();
    this._req_count = 0;
    this._events = new List<BobaosCallback>();
  }
}