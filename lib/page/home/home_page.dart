import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/core/utils/snack_bar.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'home_provider.dart';

class HomePage extends StatefulHookConsumerWidget {
  const HomePage({super.key});

  @override
  createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    var deviceList = ref.watch(deviceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备列表'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push("/setting")),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref.watch(deviceProvider.notifier).getDevices,
        child: ListView.builder(
          itemCount: deviceList.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(deviceList[index].remark ?? "Op设备"),
            subtitle: Text(deviceList[index].url!),
            onTap: () {
              // 登录设备
              ref.read(sessionProvider(deviceList[index]).notifier).login().then((v){
                if(v){
                  showSnackBar("登录成功");
                  if(context.mounted){
                    context.replace("/device/${deviceList[index].id}");
                  }
                }else{
                  showErrorSnackBar("登录失败，请检查用户名密码是否正确");
                }
              });
            },
            onLongPress: () => _showDeviceEditSheet(deviceList[index]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push("/device_add").then((device) {
          if (device != null && device is Device) {
            showSnackBar("添加成功");
            ref.read(deviceProvider.notifier).addDevice(device);
          }
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeviceEditSheet(Device device) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Transform.translate(
                offset: const Offset(0, -1.2),
                child: const Text('编辑信息'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.push("/device_modify/${device.id}").then((device) {
                  if (device != null && device is Device) {
                    showSnackBar("修改成功");
                    ref.read(deviceProvider.notifier).updateDevice(device);
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Transform.translate(
                offset: const Offset(0, -1.2),
                child: const Text('删除条目'),
              ),
              onTap: () {
                ref.read(deviceProvider.notifier).deleteDevice(device);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),);
      },
    );
  }
}
