import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/core/utils/snackbar.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceAppsPage extends HookConsumerWidget {
  final Device device;

  const DeviceAppsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            title: const Text('重启路由器'),
            subtitle: const Text('执行路由器重启'),
            leading: const Icon(Icons.restart_alt),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('重启路由器'),
                content: const Text('确定要重启路由器吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(sessionProvider(device).notifier).reboot().then((
                        v,
                      ) {
                        if (v) {
                          showSnackBar("重启成功");
                        } else {
                          showErrorSnackBar("重启失败");
                        }
                      });
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
