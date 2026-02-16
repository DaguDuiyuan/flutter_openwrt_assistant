import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/etherwake_result_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/host_hints_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class WolProvider extends StateNotifier<WolState> {
  final Ref ref;
  final Device device;

  WolProvider(this.ref, this.device) : super(WolState.initial()) {
    init();
  }

  void init() async {
    var sProvider = ref.read(sessionProvider(device).notifier);
    state = WolState(
      isSupport: await sProvider.getEtherWakeFileState(),
      hostHints: await sProvider.getHostHints(),
      interfaces: await sProvider.getNetworkList(),
      loading: false,
      sendToBroadcast: false,
      mac: null,
      interface: null,
    );
  }

  Future<EtherwakeResultResp?> sendWol() async {
    if (state.loading) return null;
    if (!state.isSupport) return null;
    if (state.mac?.isEmpty ?? true) return null;
    if (state.interface?.isEmpty ?? true) return null;

    state = state.copyWith(loading: true);
    var sProvider = ref.read(sessionProvider(device).notifier);
    var result = await sProvider.wolExec(
      state.mac!,
      state.interface!,
      state.sendToBroadcast,
    );
    state = state.copyWith(loading: false);
    return result;
  }

  void setSendToBroadcast(bool value) {
    state = state.copyWith(sendToBroadcast: value);
  }

  void setMac(String? value) {
    state = state.copyWith(mac: value);
  }

  void setInterface(String? value) {
    state = state.copyWith(interface: value);
  }
}

final wolProvider = StateNotifierProvider.family<WolProvider, WolState, Device>(
  (ref, device) => WolProvider(ref, device),
);

class WolState {
  final bool isSupport;
  final List<HostHintsResp> hostHints;
  final List<Map<String, dynamic>> interfaces;
  final bool loading;

  final String? mac;
  final String? interface;
  final bool sendToBroadcast;

  WolState.initial()
    : isSupport = false,
      hostHints = [],
      interfaces = [],
      loading = true,
      mac = null,
      interface = null,
      sendToBroadcast = false;

  WolState({
    required this.isSupport,
    required this.loading,
    required this.hostHints,
    required this.interfaces,
    required this.sendToBroadcast,
    required this.mac,
    required this.interface,
  });

  WolState copyWith({
    bool? isSupport,
    bool? loading,
    List<HostHintsResp>? hostHints,
    List<Map<String, dynamic>>? interfaces,
    bool? sendToBroadcast,
    String? mac,
    String? interface,
  }) => WolState(
    isSupport: isSupport ?? this.isSupport,
    loading: loading ?? this.loading,
    hostHints: hostHints ?? this.hostHints,
    interfaces: interfaces ?? this.interfaces,
    sendToBroadcast: sendToBroadcast ?? this.sendToBroadcast,
    mac: mac ?? this.mac,
    interface: interface ?? this.interface,
  );
}
