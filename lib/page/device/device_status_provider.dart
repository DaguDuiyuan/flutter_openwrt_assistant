import 'package:flutter/foundation.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/device_status_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/network_chart_resp.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class DeviceStateNotifier extends StateNotifier<DeviceStatusResp?> {
  final Ref ref;
  final Device device;

  DeviceStateNotifier(this.ref, this.device) : super(null) {
    _init();
  }

  void _init() async {
    getStatus();
    getNetworkList();
  }

  getStatus() async {
    state = await ref.read(sessionProvider(device).notifier).getDeviceStatus();
  }

  getNetworkList() async {
    ref.read(sessionProvider(device).notifier).getNetworkList();
  }
}

class NetChartStateNotifier
    extends StateNotifier<List<List<NetworkChartResp>>> {
  final Ref ref;
  final Device device;
  int currentIndex = 0;
  List<Map<String, dynamic>> _networkList = [];

  NetChartStateNotifier(this.ref, this.device) : super([]) {
    _init();
  }

  void _init() async {
    _networkList = await ref
        .read(sessionProvider(device).notifier)
        .getNetworkList();

    getNetworkChartData();
  }

  getNetworkChartData() async {
    if (_networkList.isEmpty) {
      return;
    }
    try {
      state = (await ref
          .read(sessionProvider(device).notifier)
          .getNetworkData(_networkList))[currentIndex];
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  setIndex(int index) async {
    currentIndex = index;
    state = [];
  }

  currentInterface() {
    try{
      return _networkList[currentIndex]['name'];
    }catch(_){
      return '';
    }
  }
}

final statsProvider =
    StateNotifierProvider.family<
      DeviceStateNotifier,
      DeviceStatusResp?,
      Device
    >((ref, device) {
      return DeviceStateNotifier(ref, device);
    });

final chartProvider =
    StateNotifierProvider.family<
      NetChartStateNotifier,
      List<List<NetworkChartResp>>,
      Device
    >((ref, device) {
      return NetChartStateNotifier(ref, device);
    });
