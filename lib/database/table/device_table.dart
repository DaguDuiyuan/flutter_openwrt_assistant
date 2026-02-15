

import 'package:isar_plus/isar_plus.dart';

part 'device_table.g.dart';

@collection
class Device {
  Device({required this.id});

  final int id;
  String? url;
  String? user;
  String? password;
  String? remark;

  @ignore
  String get postUrl => '$url/cgi-bin/luci/admin/ubus';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}