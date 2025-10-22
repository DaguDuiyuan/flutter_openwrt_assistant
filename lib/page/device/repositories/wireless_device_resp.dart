import 'package:flutter_openwrt_assistant/core/network/http_client.dart';

class WirelessDeviceResp {
  final String mac;
  String? hostName;
  String? ip;
  String? ip6;
  final int signal;
  final int connectedTime;

  final String type;
  final String interface;

  WirelessDeviceResp({
    required this.mac,
    this.hostName,
    this.ip,
    required this.signal,
    required this.connectedTime,
    required this.type,
    required this.interface,
  });

  factory WirelessDeviceResp.fromJson(Map json, Map interface) {
    return WirelessDeviceResp(
      mac: json['mac'],
      signal: json['signal'],
      connectedTime: json['connected_time'],
      type: interface['band'],
      interface: interface['ifname']
    );
  }
}

batchGetWirelessDeviceResp(BatchResponse json, List interfaces) {
  if (!json.allSuccess) return [];
  if (json.responses.isEmpty || json.responses.length <= 1) return [];

  // 设备名称等信息
  var hintMap = {};
  var hint = json.responses.last.result as List;
  if (hint.first == 0) {
    hintMap = hint.last;
  }

  var devices = <WirelessDeviceResp>[];

  try{
    for (var i = 0; i < json.responses.length - 1; i++) {
      var item = json.responses[i];
      var interface = interfaces[i];

      if (item.result is List) {
        var list = item.result as List;
        if (list.first == 0) {
          for (var e in (list.last['results'] as List)) {
            var device = WirelessDeviceResp.fromJson(e, interface);
            var hintItem = hintMap[device.mac];
            if(hintItem != null){
              device.ip = (hintItem['ipaddrs'] as List).firstOrNull;
              device.hostName = hintItem['name'];
              device.ip6 = (hintItem['ip6addrs'] as List).lastOrNull;
            }
            devices.add(device);
          }
        }
      }
    }
  }catch(e){
    return [];
  }
  return devices;
}
