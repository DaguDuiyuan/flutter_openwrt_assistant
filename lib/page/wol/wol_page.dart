import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/etherwake_result_resp.dart';
import 'package:flutter_openwrt_assistant/page/wol/wol_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WolPage extends HookConsumerWidget {
  final Device device;

  const WolPage({required this.device, super.key});

  @override
  Widget build(context, ref) {
    final provider = ref.watch(wolProvider(device));
    return Scaffold(
      appBar: AppBar(title: const Text('网络唤醒')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.isSupport
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  DropdownMenu(
                    width: MediaQuery.of(context).size.width - 32,
                    label: const Text('网络接口'),
                    onSelected: (value) {
                      ref.read(wolProvider(device).notifier).setInterface(value);
                    },
                    menuHeight: MediaQuery.of(context).size.height * 0.5,
                    dropdownMenuEntries: provider.interfaces
                        .map(
                          (e) => DropdownMenuEntry(
                            value: e['name'],
                            label: e['name'],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownMenu(
                    width: MediaQuery.of(context).size.width - 32,
                    label: const Text('目标设备'),
                    onSelected: (value) {
                      ref.read(wolProvider(device).notifier).setMac(value);
                    },
                    menuHeight: MediaQuery.of(context).size.height * 0.5,
                    dropdownMenuEntries: provider.hostHints
                        .map(
                          (e) => DropdownMenuEntry(
                            value: e.mac,
                            label: e.hostname ?? e.ipv4.firstOrNull ?? e.mac,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Checkbox(
                        value: provider.sendToBroadcast,
                        onChanged: (v) => ref
                            .read(wolProvider(device).notifier)
                            .setSendToBroadcast(v!),
                      ),
                      Text('使用广播地址发送'),
                    ],
                  ),
                ],
              ),
            )
          : Center(child: Text("未检测到 etherwake")),
      floatingActionButton: provider.isSupport
          ? FloatingActionButton(
              onPressed: () async {
                final result = await ref
                    .read(wolProvider(device).notifier)
                    .sendWol();
                if (result != null && context.mounted) {
                  showResultDialog(context, result);
                }
              },
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  void showResultDialog(BuildContext context, EtherwakeResultResp message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("正在唤醒主机"),
        content: Text("${message.stdout ?? ''}\n${message.stderr}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
