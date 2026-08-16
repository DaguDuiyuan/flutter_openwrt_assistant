/// 3cat 端口转发规则模型。
///
/// 对应 /etc/config/3cat 中的一个 `instance` 段:
///   config instance 'example'
///     option enabled '0'
///     option listen_addr '::'
///     option listen_port '25'
///     option dest_addr 'mail.my.provider'
///     option dest_port '25'
///     option protocol 'tcp'
///     option ip_prefer ''
///     option logging '0'
///     option firewall '0'
class ThreeCatRule {
  final String section;
  final bool anonymous;
  final bool enabled;
  final String listenAddr;
  final String listenPort;
  final String destAddr;
  final String destPort;
  final String protocol; // tcp / udp
  final String ipPrefer; // '' | '46' | '64' | '4' | '6'
  final bool logging;
  final bool firewall;

  const ThreeCatRule({
    this.section = '',
    this.anonymous = true,
    this.enabled = false,
    this.listenAddr = '::',
    this.listenPort = '',
    this.destAddr = '',
    this.destPort = '',
    this.protocol = 'tcp',
    this.ipPrefer = '',
    this.logging = false,
    this.firewall = false,
  });

  factory ThreeCatRule.fromJson(String section, Map<String, dynamic> json) {
    String str(String key, [String def = '']) => json[key]?.toString() ?? def;
    bool flag(String key) => str(key, '0') == '1';
    final anon = json['.anonymous'];
    return ThreeCatRule(
      section: section,
      anonymous: anon == true || anon == 1,
      enabled: flag('enabled'),
      listenAddr: str('listen_addr'),
      listenPort: str('listen_port'),
      destAddr: str('dest_addr'),
      destPort: str('dest_port'),
      protocol: str('protocol', 'tcp'),
      ipPrefer: str('ip_prefer'),
      logging: flag('logging'),
      firewall: flag('firewall'),
    );
  }

  /// 转为 uci/set、uci/add 的 values 参数。
  Map<String, dynamic> toValues() {
    return {
      'enabled': enabled ? '1' : '0',
      'listen_addr': listenAddr,
      'listen_port': listenPort,
      'dest_addr': destAddr,
      'dest_port': destPort,
      'protocol': protocol,
      if (ipPrefer.isNotEmpty) 'ip_prefer': ipPrefer,
      'logging': logging ? '1' : '0',
      'firewall': firewall ? '1' : '0',
    };
  }

  /// 规则的名称(UCI section 名)。匿名规则(自动生成 cfgxxxx)无名称。
  String get name => anonymous ? '' : section;

  /// 新增规则时 section 为空,此时展示用 id 占位。
  String get displayId =>
      section.isEmpty ? '(未保存)' : section.replaceFirst('cfg', '');

  /// 规则摘要(第一行),如 "80 → 8080"。
  /// 监听地址为通配(:: / 0.0.0.0 / 空)时省略地址,只保留端口。
  String get summary {
    final listen = _isWildcardListen ? listenPort : '$listenAddr:$listenPort';
    return '$listen → $destPort';
  }

  /// 详情行(第二行),如 "192.168.0.1 · TCP · 公网"。
  String get detail => [destAddr, ...attributes].join(' · ');

  /// 列表标题:命名规则显示名称,匿名规则显示端口对。
  String get title => anonymous ? summary : name;

  /// 列表副标题:命名规则带端口对,匿名规则只显示地址与属性。
  String get subtitle =>
      anonymous ? detail : '$summary\n${[...detail.split(' · ')].join(' · ')}';

  /// 属性列表,协议随规则动态显示(TCP / UDP)。
  List<String> get attributes => [
    protocol.toUpperCase(),
    if (firewall) '公网',
    if (logging) '日志',
  ];

  bool get _isWildcardListen =>
      listenAddr.isEmpty || listenAddr == '::' || listenAddr == '0.0.0.0';

  ThreeCatRule copyWith({
    String? section,
    bool? enabled,
    String? listenAddr,
    String? listenPort,
    String? destAddr,
    String? destPort,
    String? protocol,
    String? ipPrefer,
    bool? logging,
    bool? firewall,
  }) {
    return ThreeCatRule(
      section: section ?? this.section,
      enabled: enabled ?? this.enabled,
      listenAddr: listenAddr ?? this.listenAddr,
      listenPort: listenPort ?? this.listenPort,
      destAddr: destAddr ?? this.destAddr,
      destPort: destPort ?? this.destPort,
      protocol: protocol ?? this.protocol,
      ipPrefer: ipPrefer ?? this.ipPrefer,
      logging: logging ?? this.logging,
      firewall: firewall ?? this.firewall,
    );
  }
}
