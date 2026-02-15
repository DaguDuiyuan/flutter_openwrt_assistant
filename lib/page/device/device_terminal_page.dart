import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/core/utils/snack_bar.dart';
import 'package:flutter_openwrt_assistant/core/utils/utils.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/wireless_device_resp.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceTerminalPage extends HookConsumerWidget {
  final Device device;

  const DeviceTerminalPage({super.key, required this.device});

  // todo 有线终端
  // final tabs = ['无线终端', '有线终端'];
  // final currentIndexProvider = StateProvider((ref) => 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(wirelessListProvider(device))
        .when(
          data: (data) => data.isEmpty
              ? _emptyListView("无线终端")
              : RefreshIndicator(
                  onRefresh: () => Future(
                    () => ref.invalidate(wirelessListProvider(device)),
                  ),
                  child: ListView.separated(
                    itemCount: data.length,
                    padding: EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      WirelessDeviceResp item = data[index];
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
                            showTrailingIcon: false,
                            title: ListTile(
                              title: Text(
                                item.hostName ?? "未知设备",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              contentPadding: EdgeInsets.zero,
                              subtitle: Text(item.ip ?? item.mac),
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
                              trailing: IconButton(
                                onPressed: () =>
                                    _showDisconnectDialog(context, item, ref),
                                icon: Icon(Icons.link_off),
                              ),
                            ),
                            children: [
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Text('MAC: '), Text(item.mac)],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('信号强度: '),
                                  Text("${item.signal}dBm"),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('连接时间: '),
                                  Text(intToUsefulTime(item.connectedTime)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('接口: '),
                                  Text("${item.interface}/${item.type}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                  ),
                ),
          error: (_, _) => _emptyListView("无线终端"),
          loading: () => Center(child: CircularProgressIndicator()),
        );
  }

  Center _emptyListView(String tabText) {
    return Center(child: Text('暂无$tabText'));
  }

  void _showDisconnectDialog(
    BuildContext context,
    WirelessDeviceResp wirelessDevice,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('断开连接'),
          content: Text('是否断开该设备的连接？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(sessionProvider(device).notifier)
                    .kickDevice(wirelessDevice)
                    .then((v) {
                      if (v) {
                        showSnackBar("操作成功");
                        ref.invalidate(wirelessListProvider(device));
                      } else {
                        showSnackBar("操作失败");
                      }
                    });
                Navigator.of(context).pop();
              },
              child: Text("确定"),
            ),
          ],
        );
      },
    );
  }
}

final wirelessListProvider = FutureProvider.autoDispose
    .family<List<WirelessDeviceResp>, Device>((ref, device) async {
      return await ref.read(sessionProvider(device).notifier).getWirelessList();
    });
