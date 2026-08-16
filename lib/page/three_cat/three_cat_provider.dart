import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/session_provider.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_repository.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_rule.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

class ThreeCatProvider extends StateNotifier<ThreeCatState> {
  final Ref ref;
  final Device device;
  ThreeCatRepository? _repository;

  ThreeCatProvider(this.ref, this.device) : super(ThreeCatState.initial()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(loading: true, error: null);
    final sProvider = ref.read(sessionProvider(device).notifier);
    final token = sProvider.state.token;
    if (token == null || !sProvider.state.isConnected) {
      state = state.copyWith(loading: false, error: '未连接到路由器');
      return;
    }
    _repository = ThreeCatRepository(sProvider.client, token);
    try {
      final installed = await _repository!.checkInstalled();
      if (!installed) {
        state = state.copyWith(
          loading: false,
          installed: false,
          rules: const [],
          error: null,
        );
        return;
      }
      state = state.copyWith(installed: true);
    } catch (e) {
      // 检测失败(网络异常等),按已安装继续加载,由 load 报错。
    }
    await load();
  }

  Future<void> load() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final rules = await repo.getRules();
      state = state.copyWith(loading: false, rules: rules, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载失败: $e');
    }
  }

  /// 切换规则开关。返回 null 表示成功,否则为错误信息。
  Future<String?> toggle(ThreeCatRule rule, bool enabled) async {
    final repo = _repository;
    if (repo == null) return '未连接到路由器';
    try {
      await repo.updateRule(rule.section, rule.copyWith(enabled: enabled));
      await repo.restart();
      await load();
      return null;
    } catch (e) {
      return '操作失败: $e';
    }
  }

  /// 新增(rule.section 为空)或保存修改。返回 null 表示成功,否则为错误信息。
  Future<String?> saveRule(ThreeCatRule rule) async {
    final repo = _repository;
    if (repo == null) return '未连接到路由器';
    try {
      if (rule.section.isEmpty) {
        final section = await repo.addRule(rule);
        if (section == null) return '新增规则失败';
      } else {
        await repo.updateRule(rule.section, rule);
      }
      await repo.restart();
      await load();
      return null;
    } catch (e) {
      return '保存失败: $e';
    }
  }

  /// 删除规则。返回 null 表示成功,否则为错误信息。
  Future<String?> deleteRule(String section) async {
    final repo = _repository;
    if (repo == null) return '未连接到路由器';
    try {
      await repo.deleteRule(section);
      await repo.restart();
      await load();
      return null;
    } catch (e) {
      return '删除失败: $e';
    }
  }
}

final threeCatProvider = StateNotifierProvider.autoDispose
    .family<ThreeCatProvider, ThreeCatState, Device>(
      (ref, device) => ThreeCatProvider(ref, device),
    );

class ThreeCatState {
  final bool loading;
  final String? error;
  final List<ThreeCatRule> rules;
  final bool installed;

  const ThreeCatState({
    this.loading = true,
    this.error,
    this.rules = const [],
    this.installed = true,
  });

  ThreeCatState.initial() : this();

  ThreeCatState copyWith({
    bool? loading,
    String? error,
    List<ThreeCatRule>? rules,
    bool? installed,
  }) {
    return ThreeCatState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      rules: rules ?? this.rules,
    );
  }
}
