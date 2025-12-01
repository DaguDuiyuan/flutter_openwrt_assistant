class InterfaceResp {
  final String name;
  final bool isUp;
  final String protocol;
  final int uptime;
  final String device;
  final String? ipAddress;
  final String? netmask;
  final String? gateway;
  final List<String> dnsServers;
  final Map<String, dynamic> stats;
  final List<String>? ipv6Addresses;

  InterfaceResp({
    required this.name,
    required this.isUp,
    required this.protocol,
    required this.uptime,
    required this.device,
    this.ipAddress,
    this.netmask,
    this.gateway,
    required this.dnsServers,
    required this.stats,
    this.ipv6Addresses,
  });

  factory InterfaceResp.fromJson(Map<String, dynamic> json) {
    final ipv4List = json['ipv4-address'];
    Map<String, dynamic>? ipv4;
    if (ipv4List is List && ipv4List.isNotEmpty && ipv4List.first is Map) {
      ipv4 = ipv4List.first;
    }

    final routeList = json['route'];
    Map<String, dynamic>? route;
    if (routeList is List && routeList.isNotEmpty && routeList.first is Map) {
      route = routeList.first;
    }

    String? gatewayIp;
    if (route?['nexthop'] != null && route?['nexthop'] != '0.0.0.0') {
      gatewayIp = route?['nexthop'];
    }

    final dnsList = json['dns-server'];
    List<String> dnsServers = [];
    if (dnsList is List) {
      dnsServers = dnsList.map((e) => e.toString()).toList();
    }

    final statsMap = json['stats'];
    Map<String, dynamic> stats = {};
    if (statsMap is Map) {
      stats = Map<String, dynamic>.from(statsMap);
    }

    final ipv6List = json['ipv6-address'];
    List<String>? ipv6Addresses;
    if (ipv6List is List && ipv6List.isNotEmpty) {
      ipv6Addresses = ipv6List
          .whereType<Map>()
          .map((e) => e['address']?.toString())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
    }

    return InterfaceResp(
      name: json['interface'] ?? 'Unknown',
      isUp: json['up'] ?? false,
      protocol: json['proto'] ?? 'N/A',
      uptime: json['uptime'] ?? 0,
      device: json['device'] ?? json['l3_device'] ?? 'N/A',
      ipAddress: ipv4?['address'],
      netmask: ipv4?['mask']?.toString(),
      gateway: gatewayIp,
      dnsServers: dnsServers,
      stats: stats,
      ipv6Addresses: ipv6Addresses,
    );
  }

  String get formattedUptime {
    if (uptime <= 0) return 'N/A';

    final duration = Duration(seconds: uptime);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');

    return parts.join(' ');
  }
}

convertToInterfaceResp(
  Map<String, dynamic> interfaceRes,
  // Map<String, dynamic> deviceRes,
) {
  var interfacesList = <InterfaceResp>[];
  if (interfaceRes.containsKey('interface') &&
      interfaceRes['interface'] is List) {
    final List<dynamic> interfaceDataList = interfaceRes['interface'];
    // final Map<String, dynamic> networkStatsMap = Map<String, dynamic>.from(
    //   deviceRes,
    // );

    interfacesList = interfaceDataList.whereType<Map<String, dynamic>>().map((
      detailedInterfaceMap
    ) {
      final stats = detailedInterfaceMap['stats'];
      if (stats == null || (stats is Map && stats.isEmpty)) {
        final String? deviceName =
            detailedInterfaceMap['l3_device'] ?? detailedInterfaceMap['device'];
        // if (deviceName != null) {
        //   try {
        //     final statsContainer = networkStatsMap[deviceName];
        //     if (statsContainer is Map && statsContainer['stats'] is Map) {
        //       detailedInterfaceMap['stats'] = statsContainer['stats'];
        //     }
        //   } catch (_) {}
        // }
      }
      return InterfaceResp.fromJson(detailedInterfaceMap);
    }).toList();
  }

  return interfacesList;
}
