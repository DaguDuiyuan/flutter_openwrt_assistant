import 'package:flutter_openwrt_assistant/database/database.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:isar_plus/isar_plus.dart';


class DeviceProvider extends StateNotifier<List<Device>> {
  DeviceProvider() : super([]) {
    getDevices();
  }

  Future<void> getDevices() async {
    state = await isarDB.devices.where().findAllAsync();
  }

  Device? getDeviceById(int id) {
    return isarDB.devices.get(id);
  }

  Future<void> addDevice(Device device) async {
    await isarDB.writeAsync((isar) async {
      isar.devices.put(device);
    });
    getDevices();
  }

  Future<void> deleteDevice(Device device) async {
    await isarDB.writeAsync((isar) async {
      isar.devices.delete(device.id);
    });
    getDevices();
  }

  Future<void> updateDevice(Device device) async {
    await isarDB.writeAsync((isar) async {
      isar.devices.put(device);
    });
    getDevices();
  }
}

final deviceProvider = StateNotifierProvider<DeviceProvider, List<Device>>(
  (ref) => DeviceProvider(),
);