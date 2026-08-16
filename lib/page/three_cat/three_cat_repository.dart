import 'package:flutter_openwrt_assistant/core/network/http_client.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_rule.dart';

/// 通过 LuCI JSON-RPC(ubus 桥)管理 3cat 端口转发。
///
/// 3cat 插件没有独立 HTTP API,全部管理都落在两块:
///   1. UCI 配置 `/etc/config/3cat`(rpcd 的 `uci` ubus 对象)
///   2. 服务控制 `/etc/init.d/3cat restart`(rpcd 的 `file` 对象)
///
/// 失败时抛出 [JsonRpcException],cause 携带服务端原始返回,便于定位。
class ThreeCatRepository {
  final JsonRpcClient _client;
  final String _session;

  ThreeCatRepository(this._client, this._session);

  /// 检测 3cat 插件是否已安装。
  ///
  /// 通过 `file/stat` 检查 `/etc/config/3cat` 是否存在(与 wol 页
  /// 检测 etherwake 同款方式)。无读取权限(-32002)时无法判断,
  /// 按已安装处理,避免误报。
  Future<bool> checkInstalled() async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "file",
      "stat",
      {"path": "/etc/config/3cat"},
    ]);
    if (res.success &&
        res.result != null &&
        res.result!.isNotEmpty &&
        res.result!.first == 0) {
      return true;
    }
    if (res.error?.code == -32002) return true;
    return false;
  }

  /// 读取全部转发规则(按配置中的顺序)。
  Future<List<ThreeCatRule>> getRules() async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "get",
      {"config": "3cat"},
    ]);
    if (!res.success || res.result == null || res.result!.isEmpty) return [];
    final values = (res.result!.last as Map)['values'];
    if (values is! Map) return [];
    return values.entries
        .map(
          (e) => ThreeCatRule.fromJson(
            e.key.toString(),
            (e.value as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  /// 新增一条规则,返回新的 section 名(如 cfg0a1b2c 或自定义名称)。
  /// [name] 非空时创建命名 section,否则为匿名 section。
  Future<String?> addRule(ThreeCatRule rule, {String? name}) async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "add",
      {
        "config": "3cat",
        "type": "instance",
        if (name != null && name.isNotEmpty) "name": name,
        "values": rule.toValues(),
      },
    ]);
    if (!res.success) throw _fail('uci/add', res);
    if (res.result == null || res.result!.isEmpty) {
      throw _fail('uci/add(空返回)', res);
    }
    final section = (res.result!.last as Map)['section'];
    if (section == null) throw _fail('uci/add(无 section)', res);
    await _commit();
    return section.toString();
  }

  /// 重命名规则(UCI section 名)。改名后返回新 section 名。
  Future<String> renameRule(String oldSection, String newName) async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "rename",
      {"config": "3cat", "section": oldSection, "name": newName},
    ]);
    if (!res.success) throw _fail('uci/rename', res);
    await _commit();
    return newName;
  }

  /// 修改已有规则(section 必须存在)。
  Future<void> updateRule(String section, ThreeCatRule rule) async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "set",
      {"config": "3cat", "section": section, "values": rule.toValues()},
    ]);
    if (!res.success) throw _fail('uci/set', res);
    await _commit();
  }

  /// 删除一条规则。
  Future<void> deleteRule(String section) async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "delete",
      {"config": "3cat", "section": section},
    ]);
    if (!res.success) throw _fail('uci/delete', res);
    await _commit();
  }

  /// 提交 UCI 更改并应用(触发服务重载)。
  ///
  /// 不能用 uci/commit:luci-base 的 ACL 未授予 `commit` 方法
  /// (LuCI 前端同样用 `apply` 而非 `commit`)。`uci/apply` 会提交
  /// 所有未保存变更,并触发 config 变更事件——procd 收到后自动
  /// reload 3cat 服务(init.d 声明了 `procd_add_reload_trigger`),
  /// 无需再手动 exec 重启。
  Future<void> _commit() async {
    final res = await _client.call<List<dynamic>>("call", [
      _session,
      "uci",
      "apply",
      {"rollback": false},
    ]);
    if (!res.success) throw _fail('uci/apply', res);
  }

  /// 重启 3cat 服务使配置生效(尽力而为)。
  ///
  /// rpcd 的 file/exec 有命令白名单,LuCI 会话通常没有 exec 权限
  /// (会返回 -32002 Access denied)。此时静默降级:3cat 的 init.d
  /// 注册了 `procd_add_reload_trigger "3cat"`,commit 后 procd 会
  /// 自动重新加载运行中的实例,无需手动重启。
  Future<void> restart() async {
    try {
      await _client.call<List<dynamic>>("call", [
        _session,
        "file",
        "exec",
        {
          "command": "/etc/init.d/3cat",
          "params": ["restart"],
        },
      ]);
      // exec 被拒(-32002)属预期:依赖 procd reload trigger,静默降级。
    } catch (_) {
      // 同上,静默降级。
    }
  }

  JsonRpcException _fail(String what, JsonRpcResponse<List<dynamic>> res) {
    return JsonRpcException('$what 失败', cause: res.toString());
  }
}
