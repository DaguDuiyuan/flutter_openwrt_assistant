import 'dart:math' as math;
import 'package:intl/intl.dart';

var timeFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

String intToUsefulTime(int seconds) {
  var day = seconds ~/ (24 * 3600);
  var hour = (seconds % (24 * 3600)) ~/ 3600;
  var minute = (seconds % 3600) ~/ 60;
  var second = seconds % 60;
  
  if (day > 0) {
    return "${day}d ${hour}h ${minute}m ${second}s";
  } else {
    return "${hour}h ${minute}m ${second}s";
  }
}

String formatBytes(int bytes) {
  if (bytes == 0) return '0 B';

  const int k = 1024;
  const List<String> sizes = ['B', 'KB', 'MB', 'GB'];

  // 计算单位索引：log_k(bytes)
  int i = (math.log(bytes) / math.log(k)).floor();

  // 限制 i 不要越界（比如超过 GB）
  if (i >= sizes.length) i = sizes.length - 1;

  double value = bytes / math.pow(k, i);

  // 保留 1 位小数并格式化
  return '${value.toStringAsFixed(1)} ${sizes[i]}';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond.isNaN ||
      bytesPerSecond.isInfinite ||
      bytesPerSecond < 0) {
    return '0 bps';
  }

  final bitsPerSecond = bytesPerSecond * 8;
  if (bitsPerSecond < 1_000) return '${bitsPerSecond.toStringAsFixed(0)} bps';
  if (bitsPerSecond < 1_000_000) {
    return '${(bitsPerSecond / 1_000).toStringAsFixed(1)} Kbps';
  }
  return '${(bitsPerSecond / 1_000_000).toStringAsFixed(2)} Mbps';
}

extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}