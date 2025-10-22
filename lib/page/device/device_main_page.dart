import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/core/utils/utils.dart';
import 'package:flutter_openwrt_assistant/page/device/device_apps_page.dart';
import 'package:flutter_openwrt_assistant/page/device/device_interface_page.dart';
import 'package:flutter_openwrt_assistant/page/device/device_status_page.dart';
import 'package:flutter_openwrt_assistant/page/device/device_terminal_page.dart';
import 'package:flutter_openwrt_assistant/page/home/home_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class DeviceMainPage extends ConsumerStatefulWidget {
  final int deviceId;

  const DeviceMainPage({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceMainPage> createState() => _DeviceMainPageState();
}

class _DeviceMainPageState extends ConsumerState<DeviceMainPage> {
  final currentIndexProvider = StateProvider<int>((ref) => 0);

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final device = ref
        .watch(deviceProvider)
        .firstWhereOrNull((device) => device.id == widget.deviceId);

    return Scaffold(
      appBar: AppBar(
        title: Text(device?.remark ?? 'OpenWrt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: () {
              context.replace("/");
            },
          ),
        ],
      ),
      body: device != null
          ? IndexedStack(
              index: currentIndex,
              children: [
                DeviceStatusPage(device: device),
                DeviceTerminalPage(device: device),
                DeviceInterfacePage(device: device),
                DeviceAppsPage(device: device),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: ref.watch(currentIndexProvider),
        onDestinationSelected: (index) {
          ref.read(currentIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: const Icon(Icons.group), label: '无线终端'),
          NavigationDestination(icon: const Icon(Icons.lan), label: '接口'),
          NavigationDestination(icon: const Icon(Icons.widgets), label: '应用'),
        ],
      ),
    );
  }
}
