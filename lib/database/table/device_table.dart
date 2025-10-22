import 'package:isar_community/isar.dart';

part 'device_table.g.dart';

@collection
class Device {
  Id id = Isar.autoIncrement;
  String? url;
  String? user;
  String? password;
  String? remark;

  @ignore
  get postUrl => '$url/cgi-bin/luci/admin/ubus';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}