import 'package:dio/dio.dart';
import 'package:flutter_openwrt_assistant/core/network/api.dart';
import 'package:flutter_openwrt_assistant/core/network/http_client.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/device_status_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/etherwake_result_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/host_hints_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/interface_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/network_chart_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/wireless_device_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/wireless_interface_resp.dart';
import 'package:hooks_riverpod/legacy.dart';

class SessionState {
  final bool isLoading;
  final String? token;
  final bool isConnected;

  SessionState({this.isLoading = false, this.token, this.isConnected = false});

  SessionState copyWith({bool? isLoading, String? token, bool? isConnected}) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Device device;
  late JsonRpcClient client;

  SessionNotifier(this.device) : super(SessionState()) {
    client = JsonRpcClient(device.postUrl);
  }

  Future<bool> login() async {
    state = state.copyWith(isLoading: true);
    try {
      final uri = _buildUrl(device.url!, false, '/cgi-bin/luci/');
      var res = await (client.dio).post(
        uri.toString(),
        data: {
          "luci_username": Uri.encodeComponent(device.user!),
          "luci_password": Uri.encodeComponent(device.password!),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
          validateStatus: (code) =>
              code != null && code >= 200 && code < 400 || code == 302,
        ),
      );

      if (res.statusCode == 302 || res.statusCode == 200) {
        final setCookies = res.headers.map['set-cookie'];
        if (setCookies != null && setCookies.isNotEmpty) {
          final cookies = setCookies.join(',').split(',');
          for (final cookie in cookies) {
            if (cookie.contains('sysauth')) {
              final token = cookie.split(';')[0].split('=')[1];
              state = state.copyWith(
                isLoading: false,
                token: token,
                isConnected: true,
              );
              return true;
            }
          }
        }
      }
      state = state.copyWith(isLoading: false, isConnected: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, isConnected: false);
      return false;
    }
  }

  Future<DeviceStatusResp?> getDeviceStatus() async {
    if (!state.isConnected || state.token == null) return null;
    final res = await client.batchCall<dynamic>(
      getDeviceStatusPostData(state.token!),
    );
    return DeviceStatusResp.fromJson(res);
  }

  Future<List<WirelessDeviceResp>> getWirelessList() async {
    if (!state.isConnected || state.token == null) return [];

    // 获取无线接口
    final res = await client.call<List<dynamic>>(
      "call",
      getWirelessInterfacePostData(state.token!),
    );

    if (res.success) {
      final map = res.result?.last as Map;
      final interfaces = [];
      for (var e in map.keys) {
        var radio = map[e] as Map;
        final band = (() {
          final config = radio['config'];
          final bandValue = config is Map ? config['band'] : null;
          if (bandValue is String && bandValue.isNotEmpty) {
            return bandValue.toUpperCase();
          }
          return '-';
        })();

        if (radio.containsKey("interfaces") && radio["interfaces"] is List) {
          radio["interfaces"].forEach((iFace) {
            if (iFace.containsKey("ifname")) {
              interfaces.add({"ifname": iFace["ifname"], "band": band});
            }
          });
        }
      }

      final listRes = await client.batchCall<dynamic>(
        getWirelessListPostData(state.token!, interfaces),
      );
      return batchGetWirelessDeviceResp(listRes, interfaces);
    } else {
      return [];
    }
  }

  Future<bool> kickDevice(WirelessDeviceResp wirelessDevice) async {
    if (!state.isConnected || state.token == null) return false;
    final res = await client.call<List<dynamic>>(
      "call",
      kickWirelessPostData(state.token!, wirelessDevice),
    );

    return res.success;
  }

  Future<List<Map<String, dynamic>>> getNetworkList() async {
    if (!state.isConnected || state.token == null) return [];
    final res = await client.call(
      "call",
      getNetworkDevicePostData(state.token!),
    );
    if (res.success) {
      final deviceMap = res.result.last as Map;
      var list = deviceMap.keys
          .where((e) => e != 'lo' && deviceMap[e]['up'] != false)
          .map(
            (e1) => {
              "name": e1,
              "ip": deviceMap[e1]['type '] ?? '-',
              "mac": deviceMap[e1]['mac'] ?? '-',
            },
          )
          .toList();

      list.sort((a, b) {
        if (a['name'] == 'br-lan') return -1;
        if (b['name'] == 'br-lan') return 1;
        return a['name'].compareTo(b['name']);
      });
      return list;
    }
    return [];
  }

  Future<bool> getEtherWakeFileState() async {
    if (!state.isConnected || state.token == null) return false;
    final res = await client.call(
      "call",
      getEtherWakeFileStatePostData(state.token!),
    );
    if (res.success) {
      return res.result.first == 0;
    } else {
      return false;
    }
  }

  Future<List<HostHintsResp>> getHostHints() async {
    if (!state.isConnected || state.token == null) return [];
    final res = await client.call("call", getHostHintsPostData(state.token!));
    if (res.success && res.result.first == 0) {
      var map = res.result.last as Map;
      return map.keys.map((e) => HostHintsResp.fromJson(e, map[e])).toList();
    }
    return [];
  }

  Future<EtherwakeResultResp?> wolExec(String mac, String interface, bool sendToBroadcast) async {
    if (!state.isConnected || state.token == null) return null;
    final res = await client.call(
      "call",
      wolExecPostData(state.token!, mac, interface, sendToBroadcast),
    );

    if (res.success && res.result.first == 0) {
      return EtherwakeResultResp.fromJson(res.result.last);
    } else {
      return null;
    }
  }

  Future<List<List<List<NetworkChartResp>>>> getNetworkData(
    List<Map<String, dynamic>> networkList,
  ) async {
    if (!state.isConnected || state.token == null) return [];
    final res = await client.batchCall<dynamic>(
      getNetworkDataPostData(state.token!, networkList),
    );

    if (!res.allSuccess) return [];
    if (res.responses.isEmpty) return [];

    var networkData = <List<List<NetworkChartResp>>>[];
    for (var i = 0; i < res.responses.length; i++) {
      final response = res.responses[i];
      if (response.success) {
        final data = response.result.last['result'] as List;
        networkData.add(convertToNetworkChartResp(data));
      } else {
        networkData.add([]);
      }
    }
    return networkData;
  }

  Future<List<InterfaceResp>> getInterfaceList() async {
    if (!state.isConnected || state.token == null) return [];
    final res = await client.batchCall<dynamic>(
      getInterfacePostData(state.token!),
    );

    if (!res.allSuccess) return <InterfaceResp>[];
    if (res.responses.isEmpty) return <InterfaceResp>[];
    final interfaceRes = res.responses.first.result?.last ?? {};

    return convertToInterfaceResp(interfaceRes);
  }

  Future<List<WirelessInterfaceResp>> getWirelessInterfaceList() async {
    if (!state.isConnected || state.token == null) return [];
    // 获取无线接口
    final res = await client.call<List<dynamic>>(
      "call",
      getWirelessInterfacePostData(state.token!),
    );
    if (res.success) {
      return convertWirelessInterfaceResp(res);
    }
    return <WirelessInterfaceResp>[];
  }

  Future<bool> reboot() async {
    if (!state.isConnected || state.token == null) return false;
    final res = await client.call<List<dynamic>>(
      "call",
      rebootPostData(state.token!),
    );
    return res.success;
  }

  Uri _buildUrl(String ipAddress, bool useHttps, String path) {
    final scheme = useHttps ? 'https' : 'http';
    String host = ipAddress;
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return Uri.parse('$host$path');
    }
    return Uri.parse('$scheme://$host$path');
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider.family<SessionNotifier, SessionState, Device>(
      (ref, device) => SessionNotifier(device),
    );
