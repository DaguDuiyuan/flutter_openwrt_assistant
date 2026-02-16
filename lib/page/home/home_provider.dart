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
    await isarDB.writeAsync((isar) {
      isar.devices.put(device);
    });
    state = await isarDB.devices.where().findAllAsync();
  }

  Future<void> deleteDevice(Device device) async {
    await isarDB.writeAsync((isar) {
      isar.devices.delete(device.id);
    });
    state = await isarDB.devices.where().findAllAsync();
  }

  Future<void> updateDevice(Device device) async {
    await isarDB.writeAsync((isar) {
      isar.devices.put(device);
    });
    state = await isarDB.devices.where().findAllAsync();
  }
}

final deviceProvider = StateNotifierProvider<DeviceProvider, List<Device>>(
  (ref) => DeviceProvider(),
);