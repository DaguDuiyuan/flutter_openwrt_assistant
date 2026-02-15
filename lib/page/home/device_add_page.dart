import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_openwrt_assistant/core/utils/snack_bar.dart';
import 'package:flutter_openwrt_assistant/core/utils/utils.dart';
import 'package:flutter_openwrt_assistant/database/database.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'home_provider.dart';

class DeviceAddPage extends HookConsumerWidget {
  final int? deviceId;

  const DeviceAddPage({super.key, this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllers = [
      useTextEditingController(),
      useTextEditingController(),
      useTextEditingController(),
      useTextEditingController(),
    ];
    final titles = ['主机地址', '用户名（默认root）', '密码', '备注'];

    Device? device;
    if (deviceId != null) {
      device = useMemoized(() {
        return ref
            .read(deviceProvider)
            .firstWhereOrNull((device) => device.id == deviceId);
      }, [deviceId]);

      final isInitialized = useState(false);
      if (device != null && !isInitialized.value) {
        controllers[0].text = device.url ?? "";
        controllers[1].text = device.user ?? "";
        controllers[2].text = device.password ?? "";
        controllers[3].text = device.remark ?? "";
        isInitialized.value = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(deviceId == null ? '添加设备' : '修改设备')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => TextField(
          controller: controllers[index],
          obscureText: index == 2,
          decoration: InputDecoration(
            isDense: true,
            labelText: titles[index],
            border: const OutlineInputBorder(),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemCount: titles.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDevice(ref, context, device, controllers),
        child: const Icon(Icons.check),
      ),
    );
  }

  Future<void> _addDevice(
    WidgetRef ref,
    BuildContext context,
    Device? updateDevice,
    List<TextEditingController> controllers,
  ) async {
    // 数据校验
    if (controllers[0].text.isEmpty ||
        controllers[1].text.isEmpty ||
        controllers[2].text.isEmpty ||
        controllers[3].text.isEmpty) {
      showErrorSnackBar("请填写完整");
      return;
    }

    // 处理url
    var url = controllers[0].text;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    var device = (updateDevice ?? Device(id: isarDB.devices.autoIncrement()))
      ..url = url
      ..user = controllers[1].text
      ..password = controllers[2].text
      ..remark = controllers[3].text;

    // 保存之前判断url是否重复
    if (updateDevice == null &&
        ref.read(deviceProvider).any((element) => element.url == url)) {
      showErrorSnackBar("已存在该设备");
      return;
    }

    context.pop(device);
  }
}
