import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/core/utils/snack_bar.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_provider.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_rule.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 3cat 转发规则编辑页。rule 为 null 时表示新增。
class ThreeCatEditPage extends ConsumerStatefulWidget {
  final Device device;
  final ThreeCatRule? rule;

  const ThreeCatEditPage({super.key, required this.device, this.rule});

  @override
  ConsumerState<ThreeCatEditPage> createState() => _ThreeCatEditPageState();
}

class _ThreeCatEditPageState extends ConsumerState<ThreeCatEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _listenAddr;
  late final TextEditingController _listenPort;
  late final TextEditingController _destAddr;
  late final TextEditingController _destPort;

  late bool _enabled;
  late String _protocol;
  late String _ipPrefer;
  late bool _logging;
  late bool _firewall;
  bool _saving = false;

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _listenAddr = TextEditingController(text: rule?.listenAddr ?? '::');
    _listenPort = TextEditingController(text: rule?.listenPort ?? '');
    _destAddr = TextEditingController(text: rule?.destAddr ?? '');
    _destPort = TextEditingController(text: rule?.destPort ?? '');
    _enabled = rule?.enabled ?? false;
    _protocol = rule?.protocol ?? 'tcp';
    _ipPrefer = rule?.ipPrefer ?? '';
    _logging = rule?.logging ?? false;
    _firewall = rule?.firewall ?? false;
  }

  @override
  void dispose() {
    _listenAddr.dispose();
    _listenPort.dispose();
    _destAddr.dispose();
    _destPort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final rule = ThreeCatRule(
      section: widget.rule?.section ?? '',
      enabled: _enabled,
      listenAddr: _listenAddr.text.trim(),
      listenPort: _listenPort.text.trim(),
      destAddr: _destAddr.text.trim(),
      destPort: _destPort.text.trim(),
      protocol: _protocol,
      ipPrefer: _ipPrefer,
      logging: _logging,
      firewall: _firewall,
    );
    final error = await ref
        .read(threeCatProvider(widget.device).notifier)
        .saveRule(rule);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      showErrorSnackBar(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑转发规则' : '新增转发规则')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _listenAddr,
                    decoration: const InputDecoration(
                      labelText: '监听地址',
                      hintText: ':: 或 0.0.0.0',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入监听地址' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _listenPort,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '监听端口',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePort,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _destAddr,
                    decoration: const InputDecoration(
                      labelText: '目标地址',
                      hintText: 'IP 或域名',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入目标地址' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _destPort,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '目标端口',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePort,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _protocol,
              decoration: const InputDecoration(
                labelText: '协议',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                DropdownMenuItem(value: 'udp', child: Text('UDP')),
              ],
              onChanged: (v) => setState(() => _protocol = v ?? 'tcp'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ipPrefer,
              decoration: const InputDecoration(
                labelText: 'IP 版本',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('默认')),
                DropdownMenuItem(value: '46', child: Text('优先 IPv4')),
                DropdownMenuItem(value: '64', child: Text('优先 IPv6')),
                DropdownMenuItem(value: '4', child: Text('仅 IPv4')),
                DropdownMenuItem(value: '6', child: Text('仅 IPv6')),
              ],
              onChanged: (v) => setState(() => _ipPrefer = v ?? ''),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.only(bottom: 4),
              title: const Text('日志'),
              subtitle: const Text('将该规则日志写入系统日志'),
              value: _logging,
              onChanged: (v) => setState(() => _logging = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.only(bottom: 4),
              title: const Text('开放公网'),
              subtitle: const Text('允许来自互联网的访问(自动添加防火墙放行)'),
              value: _firewall,
              onChanged: (v) => setState(() => _firewall = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.only(bottom: 4),
              title: const Text('启用'),
              subtitle: const Text('立即生效并常驻后台'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
    );
  }

  String? _validatePort(String? value) {
    final port = int.tryParse(value?.trim() ?? '');
    if (port == null || port < 1 || port > 65535) {
      return '端口 1-65535';
    }
    return null;
  }
}
