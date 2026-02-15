import 'dart:math';

import 'package:flutter_openwrt_assistant/core/network/http_client.dart';
import 'package:flutter_openwrt_assistant/core/utils/utils.dart';

class DeviceStatusResp {
  String hostname = ""; // 主机名
  String model = ""; // 硬件型号
  String system = ""; // 系统架构
  String target = ""; // 目标平台
  String kernel = ""; // 内核版本
  String tempInfo = ""; // 温度信息

  int localtime = 0; // 本地时间
  int uptime = 0; // 运行时间

  String cpuLoad = "";
  int cpuUsage = 0;
  int memoryUsage = 0;
  String memoryDetail = "";
  String memoryCache = "";
  String memoryCacheDetail = "";
  int memoryCachePercent = 0;
  int onlineUsers = 0;
  int connections = 0;
  String connectionsDetail = "";
  int connectionsPercent = 0;

  String wanIp = "--";
  String lanIp = "--";
  String gateway = "--";
  List<String> dns = [];
  List<DiskStatusResp> disks = [];
  List<Map> networkList = [];

  DeviceStatusResp();

  factory DeviceStatusResp.fromJson(BatchResponse<dynamic> json) {
    var resp = DeviceStatusResp();

    var infoModel = json.responses.first;
    if (infoModel.success && infoModel.result.first == 0) {
      var info = infoModel.result.last;
      resp.hostname = info['hostname'];
      resp.model = info['model'];
      resp.system = info['system'];
      resp.kernel = info['kernel'];

      if (info.containsKey('release')) {
        var release = info['release'];
        resp.target = release['target'];
      }
    }

    var runInfo = json.responses[1];
    if (runInfo.success && runInfo.result.first == 0) {
      var map = runInfo.result.last;
      if (map.containsKey('load')) {
        final load1 = ((map['load'][0] as int) / 65536).toStringAsFixed(2);
        final load5 = ((map['load'][1] as int) / 65536).toStringAsFixed(2);
        final load15 = ((map['load'][2]) / 65536).toStringAsFixed(2);
        resp.cpuLoad = "$load1 $load5 $load15";
      }

      // 内存信息
      if (map.containsKey('memory')) {
        var memory = map['memory'];
        var total = memory['total'] as int;
        var available = memory['available'] as int;
        final used = total - available;
        final usage = ((used / total) * 100).round();
        resp.memoryUsage = usage;
        resp.memoryDetail = "${formatBytes(used)} / ${formatBytes(total)}";

        if (memory.containsKey('cached')) {
          var cached = memory['cached'] as int;
          resp.memoryCache = formatBytes(cached);
          resp.memoryCachePercent = ((cached / total) * 100).round();
          resp.memoryCacheDetail =
              "${formatBytes(cached)} / ${formatBytes(total)}";
        }
      }

      // 运行信息
      if (map.containsKey('uptime')) {
        resp.uptime = map['uptime'];
      }

      if (map.containsKey('localtime')) {
        resp.localtime = map['localtime'];
      }
    }

    // 温度
    var tempInfo = json.responses[7];
    if (tempInfo.success && tempInfo.result.first == 0) {
      resp.tempInfo = tempInfo.result.last['tempinfo'];
    } else {
      resp.tempInfo = "N/A";
    }

    // CPU使用率
    var cpuUsageInfo = json.responses[2];
    if (cpuUsageInfo.success && cpuUsageInfo.result.first == 0) {
      var map = cpuUsageInfo.result.last;
      var cpuUsage = map['cpuusage'] ?? "0";

      if (cpuUsage.contains('CPU:') && cpuUsage.contains('%')) {
        final cpuRegex = RegExp(r'CPU:\s*(\d+)%');
        final match = cpuRegex.firstMatch(cpuUsage);
        if (match != null && match.groupCount >= 1) {
          final value = match.group(1);
          resp.cpuUsage = int.parse(value ?? "0");
        }
      } else if (cpuUsage.contains('%')) {
        final percentRegex = RegExp(r'(\d+)%');
        final match = percentRegex.firstMatch(cpuUsage);
        if (match != null && match.groupCount >= 1) {
          final value = match.group(1);
          resp.cpuUsage = int.parse(value ?? "0");
        }
      }
    }

    // 在线用户
    var usersInfo = json.responses[3];
    if (usersInfo.success && usersInfo.result.first == 0) {
      var map = usersInfo.result.last;
      try {
        resp.onlineUsers = int.parse(map['onlineusers'].toString().trim());
      } catch (_) {}
    }

    var connectionsRes = json.responses[4];
    var maxConnectionsRes = json.responses[5];

    if (connectionsRes.success &&
        connectionsRes.result.first == 0 &&
        maxConnectionsRes.success &&
        maxConnectionsRes.result.first == 0) {
      var map = connectionsRes.result.last;
      var maxMap = maxConnectionsRes.result.last;

      var currentConnections = 0;
      var maxConnections = 0;
      try {
        currentConnections = int.parse(map['data'].toString().trim());
        maxConnections = int.parse(maxMap['data'].toString().trim());
      } catch (_) {}

      resp.connections = currentConnections;
      resp.connectionsDetail = "$currentConnections / $maxConnections";

      if (maxConnections > 0) {
        resp.connectionsPercent = ((currentConnections / maxConnections) * 100)
            .round();
      }
    }

    // 网卡信息
    var netInfo = json.responses[6];
    if (netInfo.success && netInfo.result.first == 0) {
      if (netInfo.result.last.containsKey("interface")) {
        final interfaces = netInfo.result.last['interface'] as List;
        try {
          for (var interface in interfaces) {
            if (interface['interface'] == "wan") {
              if (interface.containsKey('ipv4-address') &&
                  interface['ipv4-address'].length > 0) {
                final ipInfo = interface['ipv4-address'][0];
                resp.wanIp = "${ipInfo['address']}/${ipInfo['mask']}";
              }

              if (interface.containsKey('route') &&
                  interface['route'].length > 0) {
                for (var route in interface['route']) {
                  if (route['target'] == '0.0.0.0' && route['mask'] == 0) {
                    resp.gateway = route['nexthop'];
                    break;
                  }
                }
              }

              if (interface.containsKey("dns-server") &&
                  interface['dns-server'].length > 0) {
                var dnsServers = <String>[];
                for (
                  var i = 0;
                  i < min(interface['dns-server'].length, 2);
                  i++
                ) {
                  dnsServers.add(interface['dns-server'][i]);
                }
                resp.dns = dnsServers;
              }
            } else if (interface['interface'] == "lan") {
              if (interface.containsKey('ipv4-address') &&
                  interface['ipv4-address'].length > 0) {
                final ipInfo = interface['ipv4-address'][0];
                resp.lanIp = "${ipInfo['address']}/${ipInfo['mask']}";
              }
            }
          }
        } catch (_) {}
      }
    }

    // 磁盘信息
    var diskInfo = json.responses[8];
    if (diskInfo.success && diskInfo.result.first == 0) {
      var map = diskInfo.result.last["result"];
      if (map is List) {
        var disks = map
            .map((e) {
              final totalSize = e['size'] ?? 0;
              final freeSize = e['free'] ?? 0;
              final usedSize = totalSize - freeSize;
              final usagePercent = totalSize > 0
                  ? ((usedSize / totalSize) * 100).round()
                  : 0;
              return DiskStatusResp(
                device: e['device'] ?? "N/A",
                mount: e['mount'] ?? "N/A",
                total: formatBytes(totalSize),
                used: formatBytes(usedSize),
                free: formatBytes(freeSize),
                usagePercent: usagePercent,
              );
            })
            .where((e1) => e1.mount != '/' && e1.mount != '/dev')
            .toList();

        disks.sort((a, b) {
          if (a.mount == '/overlay') return -1;
          if (b.mount == '/overlay') return 1;
          if (a.mount == '/tmp') return -1;
          if (b.mount == '/tmp') return 1;
          return 0;
        });

        resp.disks.clear();
        resp.disks.addAll(disks);
      }
    }
    return resp;
  }

  Map<String, Object> toJson() {
    return {
      'cpu_load': cpuLoad,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'memory_detail': memoryDetail,
      'memory_cache': memoryCache,
      'memory_cache_percent': memoryCachePercent,
      'memory_cache_detail': memoryCacheDetail,
      'uptime': uptime,
      'localtime': localtime,
      'temp_info': tempInfo,
      'online_users': onlineUsers,
      'connections': connections,
      'connections_detail': connectionsDetail,
      'connections_percent': connectionsPercent,
      'wan_ip': wanIp,
      'gateway': gateway,
      'dns': dns,
      'lan_ip': lanIp,
      'disk_status': disks.map((e) => e.toJson()).toList(),
    };
  }
}

class DiskStatusResp {
  final String total;
  final String used;
  final String free;
  final int usagePercent;
  final String device;
  final String mount;

  DiskStatusResp({
    required this.total,
    required this.used,
    required this.free,
    required this.usagePercent,
    required this.device,
    required this.mount,
  });

  Map<String, Object> toJson() {
    return {
      'total': total,
      'used': used,
      'free': free,
      'usage_percent': usagePercent,
      'device': device,
      'mount': mount,
    };
  }
}
