import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/core/utils/utils.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/interface_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/wireless_interface_resp.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceInterfacePage extends HookConsumerWidget {
  final Device device;

  const DeviceInterfacePage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive(wantKeepAlive: true);
    final tabTitles = ["接口", "无线"];
    var tabController = useTabController(initialLength: 2);
    return Column(
      children: [
        TabBar(
          controller: tabController,
          dividerColor: Colors.transparent,
          tabs: tabTitles.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(child: TabBarView(
          controller: tabController,
          children: [
            interfaceView(context, ref),
            wirelessView(context, ref),
          ],
        ))
      ],
    );
  }

  RefreshIndicator interfaceView(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => Future(() => ref.invalidate(interfaceProvider(device))),
      child: ref
          .watch(interfaceProvider(device))
          .when(
            data: (data) => data.isEmpty
                ? Center(child: Text("列表为空"))
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      var item = data[i];
                      return Card(
                        elevation: 0,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            childrenPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            title: ListTile(
                              title: Text(
                                item.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              contentPadding: EdgeInsets.zero,
                              subtitle: Text(
                                _buildMinimalInterfaceSubtitle(item),
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .5),
                                  shape: BoxShape.circle,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    ref.invalidate(interfaceProvider(device));
                                  },
                                  child: Icon(_getInterfaceIcon(item.protocol)),
                                ),
                              ),
                              trailing: !item.isUp ? Text('已关闭') : null,
                            ),
                            children: [
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('运行时间: '),
                                  Text(intToUsefulTime(item.uptime)),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (item.gateway != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [Text('网关: '), Text(item.gateway!)],
                                ),
                                SizedBox(height: 8),
                              ],
                              if (item.dnsServers.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('DNS: '),
                                    Text(
                                      item.dnsServers.join("\n"),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                              if (item.ipAddress != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('IPv4: '),
                                    Text(item.ipAddress ?? "N/A"),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                              if (item.ipv6Addresses?.isNotEmpty ?? false) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('IPv6: '),
                                    Text(
                                      item.ipv6Addresses?.join("\n") ?? "N/A",
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            error: (e, _) => Center(
              child: GestureDetector(
                onTap: () => ref.invalidate(interfaceProvider(device)),
                child: Text("获取接口列表失败:(${e.toString()})"),
              ),
            ),
            loading: () => Center(child: CircularProgressIndicator()),
          ),
    );
  }

  RefreshIndicator wirelessView(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          Future(() => ref.invalidate(wirelessInterfaceProvider(device))),
      child: ref
          .watch(wirelessInterfaceProvider(device))
          .when(
            data: (data) => data.isEmpty
                ? Center(child: Text("列表为空"))
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      var item = data[i];
                      return Card(
                        elevation: 0,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            childrenPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            title: ListTile(
                              title: Text(
                                item.device != ''
                                    ? "${item.device}(${item.name})"
                                    : item.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              contentPadding: EdgeInsets.zero,
                              subtitle: Text(item.agreement),
                              leading: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.wifi),
                              ),
                            ),
                            children: [
                              Divider(),
                              if (item.signal != 0) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('信号: '),
                                    Text("${item.signal}dBm"),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Text('信道: '), Text(item.channel)],
                              ),
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Text('频段: '), Text(item.type)],
                              ),
                              SizedBox(height: 8),
                              if (item.mode != '') ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [Text('模式: '), Text(item.mode)],
                                ),
                                SizedBox(height: 8),
                              ],
                              if (item.encryption != '') ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('加密: '),
                                    Text(item.encryption),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                              if (item.bssid != '') ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [Text('BSSID: '), Text(item.bssid)],
                                ),
                                SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            error: (e, _) => Center(
              child: GestureDetector(
                onTap: () => ref.invalidate(wirelessInterfaceProvider(device)),
                child: Text("获取接口列表失败:(${e.toString()})"),
              ),
            ),
            loading: () => Center(child: CircularProgressIndicator()),
          ),
    );
  }

  String _buildMinimalInterfaceSubtitle(InterfaceResp iFace) {
    final v4 = iFace.ipAddress;
    final v6s = iFace.ipv6Addresses ?? [];
    final v6 = v6s.isNotEmpty ? v6s.first : null;
    String? shown;
    int extra = 0;
    if (v4 != null) {
      shown = v4;
      if (v6 != null) extra++;
    } else if (v6 != null) {
      shown = v6;
    }
    if (shown == null) return iFace.protocol;
    if (extra > 0) {
      return '${iFace.protocol} · $shown  +$extra';
    } else {
      return '${iFace.protocol} · $shown';
    }
  }

  IconData _getInterfaceIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'wireguard':
        return Icons.shield_outlined;
      case 'static':
        return Icons.settings_ethernet;
      case 'dhcp':
        return Icons.dns_outlined;
      default:
        return Icons.device_hub_outlined;
    }
  }
}

final interfaceProvider = FutureProvider.autoDispose
    .family<List<InterfaceResp>, Device>((ref, device) async {
      return await ref
          .read(sessionProvider(device).notifier)
          .getInterfaceList();
    });

final wirelessInterfaceProvider = FutureProvider.autoDispose
    .family<List<WirelessInterfaceResp>, Device>((ref, device) async {
      return await ref
          .read(sessionProvider(device).notifier)
          .getWirelessInterfaceList();
    });
