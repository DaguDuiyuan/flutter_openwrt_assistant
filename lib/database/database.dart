import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

late Isar isarDB;

Future<void> isarInit() async {
  final dir = await getApplicationDocumentsDirectory();
  isarDB = await Isar.open(
    [DeviceSchema],
    directory: dir.path,
    inspector: !kReleaseMode,
  );
}