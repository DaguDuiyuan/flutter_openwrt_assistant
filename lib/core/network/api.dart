import 'package:flutter_openwrt_assistant/core/network/http_client.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/wireless_device_resp.dart';

List<CallItem> getDeviceStatusPostData(String session) {
  return [
    CallItem(method: "call", id: 1, params: [session, "system", "board", {}]),
    CallItem(method: "call", id: 2, params: [session, "system", "info", {}]),
    CallItem(
      method: "call",
      id: 3,
      params: [session, "luci", "getCPUUsage", {}],
    ),
    CallItem(
      method: "call",
      id: 4,
      params: [session, "luci", "getOnlineUsers", {}],
    ),
    CallItem(
      method: "call",
      id: 5,
      params: [
        session,
        "file",
        "read",
        {"path": "/proc/sys/net/netfilter/nf_conntrack_count"},
      ],
    ),
    CallItem(
      method: "call",
      id: 6,
      params: [
        session,
        "file",
        "read",
        {"path": "/proc/sys/net/netfilter/nf_conntrack_max"},
      ],
    ),
    CallItem(
      method: "call",
      id: 7,
      params: [session, "network.interface", "dump", {}],
    ),
    CallItem(
      method: "call",
      id: 8,
      params: [session, "luci", "getTempInfo", {}],
    ),
    CallItem(
      method: "call",
      id: 9,
      params: [session, "luci", "getMountPoints", {}],
    ),
  ];
}

List<dynamic> getWirelessInterfacePostData(String session) {
  return [session, 'luci-rpc', 'getWirelessDevices', {}];
}

List<dynamic> kickWirelessPostData(String session, WirelessDeviceResp client) {
  return [
    session,
    'hostapd.${client.interface}',
    "del_client",
    {"addr": client.mac, "deauth": true, "reason": 5, "ban_time": 60000},
  ];
}

List<CallItem<dynamic>> getWirelessListPostData(String session, List interfaceMap) {
  var postData = <CallItem>[];
  for (var i = 0; i < interfaceMap.length; i++) {
    postData.add(
      CallItem(
        method: "call",
        id: i + 1,
        params: [
          session,
          "iwinfo",
          "assoclist",
          {"device": interfaceMap[i]['ifname']},
        ],
      ),
    );
  }

  postData.add(
    CallItem(
      method: "call",
      id: postData.length + 1,
      params: [session, "luci-rpc", "getHostHints", {}],
    ),
  );
  return postData;
}

List<dynamic> getNetworkDevicePostData(String session) {
  return [session, "luci-rpc", "getNetworkDevices", {}];
}

List<CallItem<dynamic>> getInterfacePostData(String session) {
  var postData = <CallItem>[
    CallItem(
      method: "call",
      id: 1,
      params: [session, "network.interface", "dump", {}],
    ),
    // CallItem(
    //   method: "call",
    //   id: 2,
    //   params: [session, "network", "device", {}],
    // ),
  ];
  return postData;
}

List<CallItem<dynamic>> getNetworkDataPostData(String session, List<Map<String, dynamic>> networkList) {
  var postData = <CallItem>[];
  for (var i = 0; i < networkList.length; i++) {
    postData.add(
      CallItem(
        method: "call",
        id: i + 1,
        params: [
          session,
          "luci",
          "getRealtimeStats",
          {'mode': 'interface', 'device': networkList[i]['name']},
        ],
      ),
    );
  }
  return postData;
}

List<dynamic> rebootPostData(String session){
  return [session, "system", "reboot", {}];
}
