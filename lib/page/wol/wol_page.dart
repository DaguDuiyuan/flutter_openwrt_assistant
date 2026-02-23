import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/etherwake_result_resp.dart';
import 'package:flutter_openwrt_assistant/page/device/repositories/host_hints_resp.dart';
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInputField(
                    labelText: '网络接口',
                    icon: Icons.network_wifi,
                    initialValue: provider.interface,
                    onChanged: (value) {
                      ref
                          .read(wolProvider(device).notifier)
                          .setInterface(value);
                    },
                    options: provider.interfaces
                        .map((e) => e['name'] as String)
                        .toList(),
                  ),
                  const SizedBox(height: 24.0),
                  _buildHostInputField(
                    labelText: '目标设备',
                    icon: Icons.computer,
                    initialValue: provider.mac,
                    onChanged: (value) {
                      ref.read(wolProvider(device).notifier).setMac(value);
                    },
                    hostHints: provider.hostHints,
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
                  ref.read(wolProvider(device).notifier).remember();
                  showResultDialog(context, result);
                }
              },
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  Widget _buildInputField({
    required String labelText,
    required IconData icon,
    required String? initialValue,
    required Function(String) onChanged,
    required List<String> options,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (value) {
        onChanged(value);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (initialValue != null && textEditingController.text.isEmpty) {
              textEditingController.text = initialValue;
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: labelText,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(icon),
              ),
              onChanged: onChanged,
              onSubmitted: (value) => onFieldSubmitted(),
            );
          },
    );
  }

  // 构建主机选择专用输入框
  Widget _buildHostInputField({
    required String labelText,
    required IconData icon,
    required String? initialValue,
    required Function(String) onChanged,
    required List<HostHintsResp> hostHints,
  }) {
    return Autocomplete<HostHintsResp>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return hostHints;
        }
        return hostHints.where((host) {
          final displayText = _getHostDisplayText(host);
          return displayText.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      displayStringForOption: (host) => _getHostDisplayText(host),
      onSelected: (host) {
        onChanged(host.mac);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (initialValue != null && textEditingController.text.isEmpty) {
              final initialHost = hostHints.firstWhere(
                (host) => host.mac == initialValue,
                orElse: () => HostHintsResp(
                  mac: initialValue,
                  hostname: null,
                  ipv4: [],
                  ipv6: [],
                ),
              );
              textEditingController.text = _getHostDisplayText(initialHost);
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: labelText,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(icon),
              ),
              onChanged: (value) {
                // 如果用户直接输入MAC地址，直接使用
                if (value.contains(':') || value.length == 17) {
                  onChanged(value);
                }
              },
              onSubmitted: (value) => onFieldSubmitted(),
            );
          },
    );
  }

  String _getHostDisplayText(HostHintsResp host) {
    final name = host.hostname ?? host.ipv4.firstOrNull;
    if (name == null) {
      return host.mac;
    }
    return '$name (${host.mac})';
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
