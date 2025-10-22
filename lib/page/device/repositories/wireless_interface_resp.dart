import 'package:flutter_openwrt_assistant/core/network/http_client.dart';

class WirelessInterfaceResp {
  String name = "";
  String device = "";
  String type = "";
  String mode = "";
  String bssid = "";
  String channel = ""; // 信道
  int signal = 0; // 信号
  String agreement = "--"; // 协议
  String encryption = ""; // 加密

  WirelessInterfaceResp();

  factory WirelessInterfaceResp.fromJson(Map json) {
    var item = WirelessInterfaceResp();
    item.type = (() {
      final config = json['config'];
      final bandValue = config is Map ? config['band'] : null;
      if (bandValue is String && bandValue.isNotEmpty) {
        return bandValue.toUpperCase();
      }
      return '-';
    })();

    item.channel = json['config']['channel'];

    if (json.containsKey("interfaces") &&
        json['interfaces'] is List &&
        json['interfaces'].isNotEmpty) {
      var interface = json['interfaces'].first;
      if (interface.containsKey("config")) {
        var interfaceConfig = interface['config'];
        item.device = interfaceConfig['ssid'];
        item.encryption = interfaceConfig['encryption'];
      }

      if (interface.containsKey("iwinfo")) {
        var interfaceStatistics = interface['iwinfo'];
        item.signal = interfaceStatistics['signal'];
        item.bssid = interfaceStatistics['bssid'];
        item.mode = interfaceStatistics['mode'];

        item.agreement = (() {
          var encryption = "";
          if (json['config'].containsKey('type')) {
            encryption += json['config']['type'];
          }

          if (interfaceStatistics.containsKey('hwmodes_text')) {
            encryption += interfaceStatistics['hwmodes_text'];
          }

          return encryption;
        })();
      }
    }

    return item;
  }
}

convertWirelessInterfaceResp(JsonRpcResponse res) {
  var list = <WirelessInterfaceResp>[];
  final map = res.result?.last as Map;
  for (var e in map.keys) {
    var radio = map[e] as Map;
    var item = WirelessInterfaceResp.fromJson(radio);
    item.name = e;
    list.add(item);
  }
  return list;
}
