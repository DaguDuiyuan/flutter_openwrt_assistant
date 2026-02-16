class HostHintsResp {
  final String mac;
  final List<String> ipv4;
  final List<String> ipv6;
  final String? hostname;

  HostHintsResp({
    required this.mac,
    required this.ipv4,
    required this.ipv6,
    required this.hostname,
  });

  factory HostHintsResp.fromJson(String mac, Map<String, dynamic> json) {
    return HostHintsResp(
      mac: mac,
      ipv4: List<String>.from(json['ipaddrs']),
      ipv6: List<String>.from(json['ip6addrs']),
      hostname: json.containsKey('name') ? json['name'] : null,
    );
  }
}
