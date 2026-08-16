import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/core/utils/snack_bar.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_provider.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_rule.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ThreeCatPage extends HookConsumerWidget {
  final Device device;

  const ThreeCatPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(threeCatProvider(device));
    final state = provider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('端口转发'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(threeCatProvider(device).notifier).load(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: state.installed
          ? FloatingActionButton(
              onPressed: () => _openEditPage(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ThreeCatState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.installed) {
      final outline = Theme.of(context).colorScheme.outline;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.extension_off, size: 56, color: outline),
              const SizedBox(height: 16),
              Text(
                '未检测到 3cat 插件',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '请在路由器 LuCI 的软件包中安装 luci-app-3cat,\n安装完成后再试',
                textAlign: TextAlign.center,
                style: TextStyle(color: outline),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(threeCatProvider(device).notifier).init(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(threeCatProvider(device).notifier).init(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (state.rules.isEmpty) {
      return const Center(child: Text('暂无转发规则,点击右下角 + 添加'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(threeCatProvider(device).notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.rules.length,
        itemBuilder: (context, index) {
          final rule = state.rules[index];
          return _buildRuleTile(context, ref, rule);
        },
      ),
    );
  }

  Widget _buildRuleTile(
    BuildContext context,
    WidgetRef ref,
    ThreeCatRule rule,
  ) {
    final enabled = rule.enabled;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          rule.summary,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(rule.detail, style: TextStyle(fontSize: 12)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled
                ? scheme.primary.withValues(alpha: .5)
                : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            rule.protocol == 'udp' ? Icons.swap_calls : Icons.swap_horiz,
            color: enabled ? scheme.primary : scheme.outline,
          ),
        ),
        trailing: Switch(
          value: enabled,
          onChanged: (value) async {
            final error = await ref
                .read(threeCatProvider(device).notifier)
                .toggle(rule, value);
            if (error != null && context.mounted) {
              showErrorSnackBar(error);
            }
          },
        ),
        onTap: () => _openEditPage(context, ref, rule),
        onLongPress: () => _confirmDelete(context, ref, rule),
      ),
    );
  }

  Future<void> _openEditPage(
    BuildContext context,
    WidgetRef ref, [
    ThreeCatRule? rule,
  ]) async {
    final changed = await context.push<bool>(
      '/3cat_edit',
      extra: (device: device, rule: rule),
    );
    if (changed == true && context.mounted) {
      showSnackBar(rule == null ? '已添加转发规则' : '已保存修改');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ThreeCatRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除转发规则'),
        content: Text('确定删除 ${rule.summary} 吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref
        .read(threeCatProvider(device).notifier)
        .deleteRule(rule.section);
    if (context.mounted) {
      error == null ? showSnackBar('已删除') : showErrorSnackBar(error);
    }
  }
}
